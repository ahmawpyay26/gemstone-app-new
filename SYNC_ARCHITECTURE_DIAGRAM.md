# Sync System Architecture Diagram

## System Components Diagram

```mermaid
graph TB
    subgraph Mobile["📱 Mobile App (Flutter)"]
        UI["UI Layer<br/>- Sync Status<br/>- Manual Sync<br/>- Conflict Resolution"]
        SyncEngine["Sync Engine<br/>- Queue Management<br/>- Offline Detection<br/>- Background Sync"]
        SQLite["SQLite Database<br/>- Core Tables<br/>- Sync Metadata<br/>- Queue & Conflicts"]
        APIClient["REST API Client<br/>- JWT Auth<br/>- Encryption<br/>- Error Handling"]
    end

    subgraph Cloud["☁️ Cloud Backend (Node.js)"]
        API["Sync API Endpoints<br/>- Initialize<br/>- Push/Pull<br/>- Bidirectional<br/>- Status & Retry"]
        SyncService["Sync Engine Service<br/>- Validate Data<br/>- Process Changes<br/>- Detect Conflicts<br/>- Resolve Conflicts"]
        PostgreSQL["PostgreSQL Database<br/>- Master Data<br/>- Sync Metadata<br/>- Conflicts<br/>- Audit Logs"]
    end

    UI -->|Trigger Sync| SyncEngine
    SyncEngine -->|Read/Write| SQLite
    SyncEngine -->|HTTP/HTTPS| APIClient
    APIClient -->|REST Calls| API
    API -->|Process| SyncService
    SyncService -->|Query/Update| PostgreSQL
    API -->|Response| APIClient
    APIClient -->|Update| SQLite
    SQLite -->|Display| UI

    style Mobile fill:#e1f5ff
    style Cloud fill:#fff3e0
    style UI fill:#b3e5fc
    style SyncEngine fill:#81d4fa
    style SQLite fill:#4fc3f7
    style APIClient fill:#29b6f6
    style API fill:#ffe0b2
    style SyncService fill:#ffcc80
    style PostgreSQL fill:#ffb74d
```

## Sync Flow Diagram

```mermaid
sequenceDiagram
    participant Mobile as Mobile App
    participant Network as Network
    participant Backend as Backend Server
    participant DB as PostgreSQL

    rect rgb(200, 220, 255)
    Note over Mobile: Offline Mode
    Mobile->>Mobile: Create/Update/Delete<br/>in SQLite
    Mobile->>Mobile: Queue changes<br/>in sync_queue
    end

    rect rgb(255, 240, 200)
    Note over Mobile,Backend: Internet Available
    Mobile->>Mobile: Detect connection
    Mobile->>Mobile: Collect local changes
    end

    rect rgb(220, 255, 220)
    Note over Mobile,Backend: Push Phase
    Mobile->>Network: POST /api/sync/push<br/>{localChanges, timestamp}
    Network->>Backend: Forward request
    Backend->>Backend: Validate data
    Backend->>Backend: Process changes
    Backend->>Backend: Detect conflicts
    Backend->>Backend: Resolve conflicts
    Backend->>DB: Update master data
    Backend->>DB: Update sync_metadata
    Backend->>Network: Response<br/>{processed, conflicts}
    Network->>Mobile: Receive response
    Mobile->>Mobile: Update sync_status
    Mobile->>Mobile: Clear sync_queue
    end

    rect rgb(220, 255, 220)
    Note over Mobile,Backend: Pull Phase
    Mobile->>Network: POST /api/sync/pull<br/>{lastSyncTimestamp}
    Network->>Backend: Forward request
    Backend->>DB: Query changes<br/>since timestamp
    Backend->>Network: Response<br/>{serverChanges}
    Network->>Mobile: Receive changes
    Mobile->>Mobile: Apply to SQLite
    Mobile->>Mobile: Update sync_status
    end

    rect rgb(200, 220, 255)
    Note over Mobile: Sync Complete
    Mobile->>Mobile: Update UI
    Mobile->>Mobile: Display sync status
    end
```

## Conflict Resolution Flow

```mermaid
graph TD
    A["Sync Request Received"] --> B["Validate Data"]
    B --> C["Process Local Changes"]
    C --> D["Detect Conflicts"]
    D --> E{Conflicts Found?}
    
    E -->|No| F["Update Server Data"]
    E -->|Yes| G["Analyze Conflict"]
    
    G --> H{Resolution Strategy}
    H -->|Server Wins| I["Keep Server Version"]
    H -->|Last Updated Wins| J{Compare Timestamps}
    H -->|Manual| K["Notify User"]
    
    J -->|Client Newer| L["Use Client Version"]
    J -->|Server Newer| I
    
    I --> M["Store Resolution"]
    L --> M
    K --> M
    
    F --> N["Update Sync Metadata"]
    M --> N
    N --> O["Return Result"]
```

## Data Sync State Machine

```mermaid
stateDiagram-v2
    [*] --> Offline: App Started
    
    Offline --> Offline: Create/Update/Delete<br/>Queue changes
    Offline --> Syncing: Internet Available
    
    Syncing --> Pushing: Start Push
    Pushing --> Pulling: Push Complete
    Pulling --> Synced: Pull Complete
    Pulling --> Conflict: Conflicts Detected
    
    Conflict --> Resolving: Resolve Conflicts
    Resolving --> Synced: Resolution Complete
    
    Synced --> Offline: Internet Lost
    Synced --> Syncing: Manual Sync
    
    Syncing --> Failed: Error Occurred
    Failed --> Offline: Retry Later
    Failed --> Syncing: Retry Now
```

## Database Sync Metadata Structure

```mermaid
graph LR
    subgraph Metadata["Sync Metadata"]
        A["user_id"]
        B["last_sync_timestamp"]
        C["sync_status"]
        D["processed_count"]
        E["conflict_count"]
        F["resolved_count"]
        G["last_error"]
    end
    
    subgraph Queue["Sync Queue"]
        H["user_id"]
        I["entity_type"]
        J["entity_id"]
        K["operation"]
        L["data"]
        M["sync_status"]
        N["retry_count"]
    end
    
    subgraph Conflicts["Sync Conflicts"]
        O["entity_type"]
        P["entity_id"]
        Q["conflict_type"]
        R["local_data"]
        S["server_data"]
        T["resolution"]
    end
    
    style Metadata fill:#b3e5fc
    style Queue fill:#c8e6c9
    style Conflicts fill:#ffe0b2
```

## Error Handling and Retry Flow

```mermaid
graph TD
    A["Sync Request"] --> B["Send to Server"]
    B --> C{Request Successful?}
    
    C -->|Yes| D["Process Response"]
    C -->|No| E{Retry Count < Max?}
    
    E -->|No| F["Mark as Failed"]
    E -->|Yes| G["Calculate Backoff"]
    
    G --> H["Wait"]
    H --> I["Increment Retry Count"]
    I --> B
    
    D --> J{Response Valid?}
    J -->|No| K["Log Error"]
    J -->|Yes| L["Update Local DB"]
    
    K --> F
    L --> M["Sync Complete"]
    F --> N["Store Error"]
    N --> O["Notify User"]
```

## Encryption and Security Flow

```mermaid
graph LR
    subgraph Client["Client Side"]
        A["Sensitive Data<br/>price, salary, etc."]
        B["Encrypt with AES-256-GCM"]
        C["Add JWT Token"]
        D["HTTPS Request"]
    end
    
    subgraph Network["Network"]
        E["TLS/SSL Encryption"]
    end
    
    subgraph Server["Server Side"]
        F["Receive HTTPS"]
        G["Verify JWT Token"]
        H["Decrypt Data"]
        I["Process & Store"]
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    
    style Client fill:#c8e6c9
    style Network fill:#fff9c4
    style Server fill:#ffccbc
```

## Offline-First Architecture Layers

```mermaid
graph TB
    subgraph UI["Presentation Layer"]
        A["UI Components"]
        B["Sync Status Indicator"]
        C["Manual Sync Button"]
        D["Conflict Resolution UI"]
    end
    
    subgraph Business["Business Logic Layer"]
        E["Sync Engine"]
        F["Queue Manager"]
        G["Conflict Resolver"]
        H["Retry Handler"]
    end
    
    subgraph Data["Data Layer"]
        I["SQLite ORM"]
        J["Local Cache"]
        K["Sync Metadata"]
    end
    
    subgraph Storage["Storage Layer"]
        L["SQLite Database"]
        M["File System"]
    end
    
    subgraph Network["Network Layer"]
        N["HTTP Client"]
        O["JWT Handler"]
        P["Encryption Module"]
    end
    
    A --> E
    B --> E
    C --> E
    D --> G
    
    E --> F
    E --> G
    E --> H
    
    F --> I
    G --> I
    H --> I
    
    I --> J
    I --> K
    
    J --> L
    K --> L
    
    E --> N
    N --> O
    N --> P
    
    style UI fill:#b3e5fc
    style Business fill:#c8e6c9
    style Data fill:#fff9c4
    style Storage fill:#ffccbc
    style Network fill:#f8bbd0
```

## Sync Timing and Triggers

```mermaid
graph TD
    A["App Lifecycle"] --> B{Event Type?}
    
    B -->|App Start| C["Check Last Sync"]
    B -->|Periodic| D["Background Sync<br/>Every 5 mins"]
    B -->|User Action| E["Manual Sync"]
    B -->|Network Change| F["Connectivity Check"]
    
    C --> G["Determine Sync Strategy"]
    D --> G
    E --> G
    F --> G
    
    G --> H{Internet Available?}
    H -->|No| I["Queue Changes"]
    H -->|Yes| J["Initiate Sync"]
    
    I --> K["Update UI<br/>Offline Mode"]
    J --> L["Execute Push"]
    L --> M["Execute Pull"]
    M --> N["Update UI<br/>Sync Complete"]
    
    style A fill:#b3e5fc
    style B fill:#81d4fa
    style C fill:#4fc3f7
    style D fill:#4fc3f7
    style E fill:#4fc3f7
    style F fill:#4fc3f7
    style G fill:#29b6f6
    style H fill:#0288d1
    style I fill:#0277bd
    style J fill:#0277bd
    style K fill:#01579b
    style L fill:#01579b
    style M fill:#01579b
    style N fill:#01579b
```

## Conflict Resolution Decision Tree

```mermaid
graph TD
    A["Conflict Detected"] --> B["Get Client Data"]
    A --> C["Get Server Data"]
    
    B --> D["Extract Timestamps"]
    C --> D
    
    D --> E{Resolution Strategy}
    
    E -->|Server Wins| F["Use Server Data"]
    E -->|Last Updated Wins| G{Compare Timestamps}
    E -->|Manual| H["Prompt User"]
    
    G -->|Client Newer| I["Use Client Data"]
    G -->|Server Newer| F
    G -->|Same Time| J["Use Server Data<br/>Default"]
    
    F --> K["Store Resolution"]
    I --> K
    J --> K
    H --> K
    
    K --> L["Log Conflict"]
    L --> M["Update Sync Status"]
    M --> N["Notify User"]
    
    style A fill:#ffccbc
    style E fill:#ffab91
    style F fill:#ff8a65
    style I fill:#ff8a65
    style J fill:#ff8a65
    style H fill:#ff7043
    style K fill:#ff5722
    style L fill:#e64a19
    style M fill:#d84315
    style N fill:#bf360c
```

## Performance Optimization Strategies

```mermaid
graph TB
    subgraph Optimization["Performance Optimization"]
        A["Batch Processing<br/>Process 100 items/batch"]
        B["Compression<br/>Gzip sync payload"]
        C["Caching<br/>Cache metadata"]
        D["Indexing<br/>DB indexes"]
        E["Lazy Loading<br/>Load on demand"]
        F["Pagination<br/>Limit results"]
    end
    
    subgraph Benefits["Benefits"]
        G["Reduced Latency"]
        H["Lower Bandwidth"]
        I["Faster Queries"]
        J["Better UX"]
    end
    
    A --> G
    A --> H
    B --> H
    C --> I
    D --> I
    E --> J
    F --> J
    
    style Optimization fill:#c8e6c9
    style Benefits fill:#b3e5fc
```

---

**Diagram Version:** 1.0.0
**Last Updated:** May 31, 2026
**Format:** Mermaid Diagrams
