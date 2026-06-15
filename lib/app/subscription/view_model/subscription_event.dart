import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadOfferingsEvent extends SubscriptionEvent {
  const LoadOfferingsEvent();
}

class SelectPlanEvent extends SubscriptionEvent {
  final int index;
  const SelectPlanEvent(this.index);

  @override
  List<Object?> get props => [index];
}

class PurchasePackageEvent extends SubscriptionEvent {
  final Package package;
  const PurchasePackageEvent(this.package);

  @override
  List<Object?> get props => [package];
}

class RestorePurchasesEvent extends SubscriptionEvent {
  const RestorePurchasesEvent();
}
