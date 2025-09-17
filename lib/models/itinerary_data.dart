class ItineraryData {
  String? destination;
  int? days;
  String? budget;
  String? activities;
  int? travelers;
  String? dates;
  String? accommodation;
  String? travelStyle;

  ItineraryData({
    this.destination,
    this.days,
    this.budget,
    this.activities,
    this.travelers,
    this.dates,
    this.accommodation,
    this.travelStyle,
  });

  Map<String, dynamic> toMap() {
    return {
      'destination': destination,
      'days': days,
      'budget': budget,
      'activities': activities,
      'travelers': travelers,
      'dates': dates,
      'accommodation': accommodation,
      'travelStyle': travelStyle,
    };
  }

  factory ItineraryData.fromMap(Map<String, dynamic> map) {
    return ItineraryData(
      destination: map['destination'],
      days: map['days'],
      budget: map['budget'],
      activities: map['activities'],
      travelers: map['travelers'],
      dates: map['dates'],
      accommodation: map['accommodation'],
      travelStyle: map['travelStyle'],
    );
  }

  bool isComplete() {
    return destination != null &&
        days != null &&
        budget != null &&
        travelers != null;
  }
}