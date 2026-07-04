# Broker Media Box - Architecture Review

**Base Commit:** 965cfa0 (PAT #204 SUCCESS)

**Date:** July 4, 2026

**Status:** Analysis Only (No Code Changes)

---

## Executive Summary

The Broker Media Box feature will allow users to store and manage media (photos and videos) for each broker consignment. This document provides a comprehensive architecture review, data model recommendations, UI design plan, and step-by-step implementation roadmap.

**Key Recommendation:** Extend existing `BrokerConsignment` model with media metadata rather than creating a separate `BrokerMedia` model. This keeps the architecture simple while maintaining separation of concerns.

---

## 1. Current Broker Data Model Analysis

### BrokerConsignment Model (Current)

**Location:** `lib/core/local/models.dart` (lines 922-975)

**Current Fields:**
```dart
class BrokerConsignment {
  String id;                           // Unique ID
  String purchaseId;                   // Reference to Purchase
  
  // Quantities
  double consignedQuantity;
  double soldQuantity;
  double returnedQuantity;
  
  // Historical Data
  BrokerHistoricalData historicalData;
  
  // Broker Info
  String brokerName;
  String brokerPhone;
  String brokerAddress;
  String? brokerSocialAccount;
  
  // Additional
  String notes;
  List<String> photoPaths;            // ← Already has photo storage!
  
  // Timestamps
  int createdAt;
  int updatedAt;
  int? deletedAt;
}
```

**Key Observation:** The model already has a `photoPaths` field (line 942) that stores a list of photo file paths. This is the foundation we can build upon.

### Current Hive Adapter

**TypeId:** 11

**Field Count:** 15 fields

**Backward Compatibility:** Adding new fields will require incrementing field count from 15 to 17 (for photo and video metadata).

---

## 2. Data Model Recommendation

### Option A: Extend BrokerConsignment (RECOMMENDED)

**Approach:** Add media metadata fields directly to `BrokerConsignment`

**Pros:**
- ✅ Simple, minimal changes
- ✅ Existing `photoPaths` field already in place
- ✅ One-to-one relationship (one consignment = one media box)
- ✅ No new Hive adapters needed
- ✅ Backward compatible (add as optional fields)
- ✅ Easier querying (all data in one record)
- ✅ Atomic updates (consignment + media updated together)

**Cons:**
- ❌ BrokerConsignment model becomes slightly larger
- ❌ Less flexible if media needs to be shared across multiple consignments

**Recommended Fields to Add:**
```dart
// In BrokerConsignment class
List<String> videoPaths;              // Paths to broker videos
List<BrokerMediaMetadata> mediaMetadata; // Metadata for all media
```

**New Class: BrokerMediaMetadata**
```dart
class BrokerMediaMetadata {
  String id;                          // Unique ID for this media item
  String filePath;                    // Full path to file
  String mediaType;                   // 'photo' | 'video'
  String sourceType;                  // 'camera' | 'gallery'
  int fileSize;                       // Size in bytes
  int createdAt;                      // Timestamp when captured/uploaded
  String? caption;                    // Optional user caption
  bool isUploaded;                    // Whether synced to cloud
}
```

### Option B: Create Separate BrokerMedia Model

**Approach:** Create new `BrokerMedia` model with foreign key to `BrokerConsignment`

**Pros:**
- ✅ Cleaner separation of concerns
- ✅ More flexible for future features
- ✅ Can support multiple media per consignment easily

**Cons:**
- ❌ Requires new Hive adapter (new typeId)
- ❌ More complex queries (join-like operations)
- ❌ Larger database footprint
- ❌ More code to maintain

**Not Recommended** because:
- Adds unnecessary complexity
- BrokerConsignment already has `photoPaths`
- One-to-one relationship doesn't require separate model

---

## 3. Storage Method Recommendation

### Option A: Local File Paths (RECOMMENDED)

**Approach:** Store actual files in app's document directory, keep paths in Hive

**Structure:**
```
/app_documents/
  /broker_media/
    /broker_consignment_id_1/
      photo_20260704_120000.jpg
      video_20260704_121000.mp4
      photo_20260704_122000.jpg
    /broker_consignment_id_2/
      photo_20260704_130000.jpg
```

**Pros:**
- ✅ Files persist locally
- ✅ Works offline
- ✅ No cloud dependency
- ✅ User has full control
- ✅ Easy to backup/export

**Cons:**
- ❌ Limited by device storage
- ❌ Manual cleanup needed for deleted items
- ❌ No automatic cloud sync

### Option B: Hive Record with Base64 Encoding

**Approach:** Store media as base64 strings in Hive records

**Pros:**
- ✅ Everything in one place
- ✅ No file system management
- ✅ Atomic transactions

**Cons:**
- ❌ Hive database becomes very large
- ❌ Slow read/write for large files
- ❌ Memory issues with large videos
- ❌ Not practical for videos

**Not Recommended** for this use case.

### Recommendation

**Use Option A: Local File Paths**

- Store media files in `/app_documents/broker_media/{consignmentId}/`
- Store file paths in `BrokerConsignment.photoPaths` and `BrokerConsignment.videoPaths`
- Store metadata in `BrokerConsignment.mediaMetadata`
- Implement cleanup when consignment is deleted

---

## 4. Required Permissions

### Android Permissions

**In `AndroidManifest.xml`:**
```xml
<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Photo/Video Gallery Access -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

<!-- Write to app directory (no permission needed for app-specific directory) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS Permissions

**In `Info.plist`:**
```xml
<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>ကျောက်မျက်ဓာတ်ပုံ ရိုက်ယူရန် ကင်မရာ အသုံးပြုခွင့်လိုအပ်ပါသည်</string>

<!-- Photo Library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>ကျောက်မျက်ဓာတ်ပုံ ရွေးချယ်ရန် ဓာတ်ပုံ စာကြည့်တိုက် အသုံးပြုခွင့်လိုအပ်ပါသည်</string>

<!-- Camera Roll -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>ကျောက်မျက်ဓာတ်ပုံ သိမ်းဆည်းရန် ဓာတ်ပုံ စာကြည်တိုက် အသုံးပြုခွင့်လိုအပ်ပါသည်</string>
```

### Runtime Permissions (Flutter)

**Package:** `permission_handler`

**Permissions to Request:**
- `Permission.camera` - Camera access
- `Permission.photos` - Photo gallery access
- `Permission.videos` - Video gallery access

**Request Flow:**
1. Check permission status
2. If denied, request from user
3. If granted, proceed with camera/gallery
4. If permanently denied, show settings link

---

## 5. UI Location and Design

### UI Location Options

#### Option A: Broker Details Page (RECOMMENDED)

**Location:** Dedicated tab or section in broker consignment detail page

**Pros:**
- ✅ Contextual to specific broker
- ✅ User can see broker info + media together
- ✅ Natural place to manage broker documentation
- ✅ Reduces navigation

**Cons:**
- ❌ Requires detail page redesign

#### Option B: Broker List Page

**Location:** Expandable media section in list item

**Pros:**
- ✅ Quick access from list
- ✅ See media count at a glance

**Cons:**
- ❌ Limited space for media preview
- ❌ Cluttered list view

#### Option C: Separate Media Gallery Page

**Location:** Dedicated page for broker media

**Pros:**
- ✅ Full-screen media browsing
- ✅ Organized view

**Cons:**
- ❌ Extra navigation step
- ❌ Separated from broker context

**Recommendation:** Option A (Broker Details Page)

### Recommended UI Design

#### Media Box Card

**Location:** Broker Details Page (new tab or section)

**Components:**

```
┌─ Media Box ─────────────────────────────────┐
│                                              │
│  Photos (3)                Videos (1)       │
│  ┌──────┐ ┌──────┐ ┌──────┐               │
│  │ Photo│ │ Photo│ │ Photo│               │
│  │  1   │ │  2   │ │  3   │               │
│  └──────┘ └──────┘ └──────┘               │
│                                              │
│  ┌──────────────────────────────────────┐  │
│  │  + Add Photo    + Add Video          │  │
│  │  📷 Camera      🎥 Camera            │  │
│  │  🖼️ Gallery     📹 Gallery           │  │
│  └──────────────────────────────────────┘  │
│                                              │
│  Total: 4 items | Size: 45.2 MB            │
│                                              │
└──────────────────────────────────────────────┘
```

#### Media Grid View

**When user taps on media:**
- Show full-screen preview
- Allow delete/rename
- Show metadata (date, size, source)
- Allow sharing

#### Add Media Options

**Floating Action Button or Menu:**
1. **📷 Take Photo** - Open camera
2. **🎥 Record Video** - Open video recorder
3. **🖼️ Pick Photo** - Open gallery
4. **📹 Pick Video** - Open video gallery

---

## 6. Impact on App Size and Performance

### App Size Impact

**Current Estimate:**
- BrokerConsignment model: ~2 KB per record
- With media metadata: ~3 KB per record
- Hive adapter changes: ~1 KB

**Total:** ~1-2 KB additional per consignment

**Media Files:** Stored on device, not in app bundle
- Photos: 2-5 MB each (typical)
- Videos: 10-50 MB each (typical)
- User controls storage via device

### Performance Impact

**Positive:**
- ✅ Local storage = fast access
- ✅ No network calls for media
- ✅ Works offline

**Negative:**
- ❌ File I/O operations slower than in-memory
- ❌ Large media files slow to load
- ❌ Device storage usage increases

**Mitigation:**
- Lazy load thumbnails
- Compress photos before saving
- Limit video resolution
- Implement cleanup for old media
- Show progress indicators during upload

### Database Performance

**Query Impact:**
- Minimal (media paths are just strings)
- Filtering by media count: O(n) scan
- Sorting by media date: O(n log n)

**Optimization:**
- Index on consignmentId (already done)
- Cache media count in metadata
- Lazy load media list

---

## 7. Backup and Export Considerations

### Backup Strategy

**Local Backup:**
- Export consignment data as JSON
- Include media file references
- Store in cloud or external storage

**Cloud Backup:**
- Optional sync to cloud storage
- Encrypted transmission
- User-controlled sync

### Export Options

**User Can Export:**
1. **Consignment Details** - JSON with all data
2. **Media Files** - ZIP archive with all media
3. **Full Report** - PDF with photos and details

**Implementation:**
- Add "Export" button in broker details
- Generate ZIP with consignment data + media
- Save to Downloads folder
- Allow sharing via email/messaging

---

## 8. Risk Analysis

### Technical Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Device storage full | 🟡 Medium | Show storage warning, implement cleanup |
| File corruption | 🟡 Medium | Verify file integrity on load |
| Permission denied | 🟢 Low | Graceful fallback, show settings link |
| Large file handling | 🟡 Medium | Compress, limit resolution, show progress |
| Memory overflow | 🟡 Medium | Stream large files, lazy load thumbnails |

### Data Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Media loss on uninstall | 🔴 High | Backup to cloud or export |
| Accidental deletion | 🟡 Medium | Soft delete, recovery option |
| Privacy concerns | 🟡 Medium | Encrypt files, secure storage |
| Sync conflicts | 🟢 Low | Timestamp-based conflict resolution |

### UX Risks

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Slow media loading | 🟡 Medium | Lazy load, show progress |
| Permission requests | 🟡 Medium | Explain why needed, one-time request |
| Storage management | 🟡 Medium | Show storage usage, cleanup options |

---

## 9. Recommended Implementation Phases

### Phase 1: Data Model & Storage (Week 1)

**Tasks:**
1. Add `videoPaths` field to `BrokerConsignment`
2. Create `BrokerMediaMetadata` class
3. Update `BrokerConsignmentAdapter` (field count 15 → 17)
4. Create media storage directory structure
5. Write unit tests for model

**Deliverables:**
- Updated models.dart
- Storage directory created on app start
- Backward compatibility verified

**Effort:** 1-2 days

### Phase 2: Camera & Gallery Integration (Week 1-2)

**Tasks:**
1. Add `image_picker` and `video_player` packages
2. Implement camera permission handling
3. Implement photo capture flow
4. Implement video recording flow
5. Implement gallery picker for photos
6. Implement gallery picker for videos
7. Save media with metadata

**Deliverables:**
- Camera integration working
- Gallery integration working
- Media saved with metadata
- Unit tests

**Effort:** 2-3 days

### Phase 3: UI Implementation (Week 2)

**Tasks:**
1. Create media box card widget
2. Create media grid view
3. Create media preview screen
4. Implement add media buttons
5. Implement delete media
6. Implement rename media
7. Show storage usage

**Deliverables:**
- Media box UI complete
- All interactions working
- UI tests

**Effort:** 2-3 days

### Phase 4: Advanced Features (Week 3)

**Tasks:**
1. Implement media compression
2. Implement thumbnail caching
3. Implement cleanup on delete
4. Implement export/backup
5. Implement cloud sync (optional)
6. Performance optimization

**Deliverables:**
- Compression working
- Export/backup working
- Performance optimized
- Integration tests

**Effort:** 2-3 days

### Phase 5: Testing & Polish (Week 3-4)

**Tasks:**
1. End-to-end testing
2. Performance testing
3. Storage testing
4. Permission testing
5. Edge case handling
6. Documentation

**Deliverables:**
- All tests passing
- Documentation complete
- Ready for production

**Effort:** 1-2 days

---

## 10. Step-by-Step Implementation Plan

### Step 1: Update Data Models

**File:** `lib/core/local/models.dart`

**Changes:**
1. Add `BrokerMediaMetadata` class (before `BrokerConsignment`)
2. Add `videoPaths` field to `BrokerConsignment`
3. Add `mediaMetadata` field to `BrokerConsignment`
4. Update `BrokerConsignmentAdapter.read()` to handle new fields
5. Update `BrokerConsignmentAdapter.write()` to write new fields
6. Increment field count from 15 to 17

**Backward Compatibility:**
- Old records load with empty `videoPaths` and `mediaMetadata`
- New records save with both fields

### Step 2: Create Storage Manager

**File:** `lib/core/services/media_storage_service.dart`

**Responsibilities:**
- Create media directory structure
- Save photo/video files
- Generate file paths
- Delete media files
- Calculate storage usage
- Cleanup old files

**Methods:**
```dart
Future<String> savePhoto(File file, String consignmentId)
Future<String> saveVideo(File file, String consignmentId)
Future<void> deleteMedia(String filePath)
Future<int> getStorageUsage()
Future<void> cleanupConsignmentMedia(String consignmentId)
```

### Step 3: Implement Camera Integration

**File:** `lib/features/broker/presentation/pages/broker_details_page.dart`

**Add:**
- Camera permission handling
- Photo capture flow
- Video recording flow
- Save media to storage
- Update BrokerConsignment record

**Packages:**
- `image_picker` - Camera & gallery
- `permission_handler` - Permissions

### Step 4: Implement Gallery Integration

**File:** `lib/features/broker/presentation/pages/broker_details_page.dart`

**Add:**
- Gallery permission handling
- Photo picker flow
- Video picker flow
- Save media to storage
- Update BrokerConsignment record

### Step 5: Create Media Box UI

**Files:**
- `lib/features/broker/presentation/widgets/media_box_card.dart`
- `lib/features/broker/presentation/widgets/media_grid.dart`
- `lib/features/broker/presentation/widgets/media_preview.dart`

**Components:**
1. Media box card showing photos/videos
2. Media grid for browsing
3. Media preview screen
4. Add media buttons
5. Delete/rename options

### Step 6: Implement Export/Backup

**File:** `lib/core/services/export_service.dart`

**Features:**
- Export consignment as JSON
- Export media as ZIP
- Export full report as PDF
- Share via email/messaging

---

## 11. Success Criteria

### Functional Requirements

- ✅ User can take photo with camera
- ✅ User can record video with camera
- ✅ User can pick photo from gallery
- ✅ User can pick video from gallery
- ✅ Media stored under specific broker
- ✅ Media persists after app restart
- ✅ User can view media in grid
- ✅ User can delete media
- ✅ User can rename media
- ✅ User can export media
- ✅ Storage usage displayed

### Non-Functional Requirements

- ✅ Photos load in < 1 second
- ✅ Videos load in < 2 seconds
- ✅ App size increase < 5 MB
- ✅ No memory leaks
- ✅ Works offline
- ✅ Handles large files (100+ MB)
- ✅ Permissions handled gracefully

### Testing Requirements

- ✅ Unit tests for storage service
- ✅ Unit tests for media metadata
- ✅ Widget tests for media box UI
- ✅ Integration tests for camera flow
- ✅ Integration tests for gallery flow
- ✅ End-to-end tests for full flow

---

## 12. Conclusion

### Key Recommendations

1. **Extend BrokerConsignment model** with `videoPaths` and `mediaMetadata` fields
2. **Store media locally** in app's document directory
3. **Use `image_picker` package** for camera and gallery integration
4. **Implement media box UI** in broker details page
5. **Add export/backup** functionality for user data protection

### Why This Approach

- ✅ Simple and maintainable
- ✅ Backward compatible
- ✅ Works offline
- ✅ User has full control
- ✅ Minimal performance impact
- ✅ Scalable for future features

### Next Steps

1. Get stakeholder approval for this architecture
2. Create detailed design mockups for UI
3. Begin Phase 1 implementation
4. Set up testing infrastructure
5. Plan deployment strategy

---

**Document Status:** ✅ Complete - Ready for Implementation

**Prepared by:** Manus AI

**Date:** July 4, 2026
