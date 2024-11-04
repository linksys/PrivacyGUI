mixin PortUtilMixin {
  bool doesRangeOverlap(int range1First, int range1Last, int range2First, int range2Last) {
            return range1First <= range2Last && range2First <= range1Last;
  }
}