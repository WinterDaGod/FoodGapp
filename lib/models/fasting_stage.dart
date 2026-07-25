class FastingStage {
  final int index;
  final String name;
  final String description;
  final double startHour;

  const FastingStage({
    required this.index,
    required this.name,
    required this.description,
    required this.startHour,
  });

  static const List<FastingStage> allStages = [
    FastingStage(
      index: 1,
      name: 'Blood sugar rises',
      description: 'Your body is processing your last meal. Insulin levels are high as your body breaks down carbohydrates into glucose for energy.',
      startHour: 0,
    ),
    FastingStage(
      index: 2,
      name: 'Blood sugar falls',
      description: 'As your body finishes processing your meal, insulin levels start to drop and blood sugar begins to normalize.',
      startHour: 2,
    ),
    FastingStage(
      index: 3,
      name: 'Blood sugar normalizes',
      description: 'Your blood sugar reaches a stable, healthy baseline. Your body begins to look for alternative energy sources.',
      startHour: 5,
    ),
    FastingStage(
      index: 4,
      name: 'Gluconeogenesis starts',
      description: 'Your body begins to create glucose from non-carbohydrate sources, like stored fats and proteins, to maintain energy.',
      startHour: 8,
    ),
    FastingStage(
      index: 5,
      name: 'Glycogen stores decrease',
      description: 'Your stored glycogen in the liver is being used up. You are transitioning closer to a fat-burning state.',
      startHour: 10,
    ),
    FastingStage(
      index: 6,
      name: 'Ketosis starts',
      description: 'Fat burning truly begins. Your liver starts producing ketones, which your brain and body use as a highly efficient fuel source.',
      startHour: 12,
    ),
    FastingStage(
      index: 7,
      name: 'Fat burning increases',
      description: 'Your body is now primarily using stored fat for energy. Metabolic flexibility is increasing.',
      startHour: 14,
    ),
    FastingStage(
      index: 8,
      name: 'Autophagy begins',
      description: 'The body starts a "self-cleaning" process, where damaged cell components are broken down and recycled for new parts.',
      startHour: 16,
    ),
    FastingStage(
      index: 9,
      name: 'Autophagy peaks',
      description: 'Cellular repair and detoxification are at their highest. This stage is associated with longevity and anti-aging benefits.',
      startHour: 18,
    ),
    FastingStage(
      index: 10,
      name: 'Growth hormone increases',
      description: 'Levels of human growth hormone (HGH) rise significantly, helping to preserve muscle mass and improve metabolic health.',
      startHour: 24,
    ),
    FastingStage(
      index: 11,
      name: 'Immune system reset',
      description: 'Long-term fasting can trigger the regeneration of old immune cells, essentially refreshing your body\'s defense system.',
      startHour: 48,
    ),
  ];

  static FastingStage getStageForHours(double hours) {
    return allStages.lastWhere(
      (stage) => hours >= stage.startHour,
      orElse: () => allStages.first,
    );
  }
}
