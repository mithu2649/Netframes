import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class FetchHomeData extends HomeEvent {
  final String provider;

  const FetchHomeData(this.provider);

  @override
  List<Object> get props => [provider];
}

class SelectProvider extends HomeEvent {
  final String provider;

  const SelectProvider(this.provider);

  @override
  List<Object> get props => [provider];
}
