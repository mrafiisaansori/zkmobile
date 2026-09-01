import 'package:equatable/equatable.dart';

class CheckoutState extends Equatable {
  final int offlinePending;

  const CheckoutState({this.offlinePending = 0});

  CheckoutState copyWith({int? offlinePending}) =>
      CheckoutState(offlinePending: offlinePending ?? this.offlinePending);

  @override
  List<Object?> get props => [offlinePending];
}
