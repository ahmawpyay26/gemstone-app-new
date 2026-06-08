import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/gemstone_repository_impl.dart';
import '../../../data/datasources/local/app_database.dart';

// Events
abstract class InventoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadInventory extends InventoryEvent {}

// States
abstract class InventoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}
class InventoryLoading extends InventoryState {}
class InventoryLoaded extends InventoryState {
  final List<LocalGemstone> stones;
  InventoryLoaded(this.stones);
  @override
  List<Object?> get props => [stones];
}
class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);
}

// BLoC
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GemstoneRepositoryImpl repository;

  InventoryBloc({required this.repository}) : super(InventoryInitial()) {
    on<LoadInventory>((event, emit) async {
      emit(InventoryLoading());
      try {
        final stones = await repository.getGemstones();
        emit(InventoryLoaded(stones));
      } catch (e) {
        emit(InventoryError(e.toString()));
      }
    });
  }
}
