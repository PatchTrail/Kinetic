enum MuscleGroup {
  chest,
  upperChest,
  lats,
  traps,
  lowerBack,
  anteriorDelts,
  lateralDelts,
  posteriorDelts,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  quads,
  hamstrings,
  glutes,
  calves,
}

extension MuscleGroupExtension on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Pectorals (Chest)';
      case MuscleGroup.upperChest:
        return 'Upper Chest';
      case MuscleGroup.lats:
        return 'Latissimus Dorsi (Lats)';
      case MuscleGroup.traps:
        return 'Trapezius (Traps)';
      case MuscleGroup.lowerBack:
        return 'Lower Back';
      case MuscleGroup.anteriorDelts:
        return 'Front Delts';
      case MuscleGroup.lateralDelts:
        return 'Side Delts';
      case MuscleGroup.posteriorDelts:
        return 'Rear Delts';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.abs:
        return 'Abdominals (Core)';
      case MuscleGroup.obliques:
        return 'Obliques';
      case MuscleGroup.quads:
        return 'Quadriceps (Quads)';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
    }
  }

  bool get isFront {
    switch (this) {
      case MuscleGroup.chest:
      case MuscleGroup.upperChest:
      case MuscleGroup.anteriorDelts:
      case MuscleGroup.lateralDelts:
      case MuscleGroup.biceps:
      case MuscleGroup.forearms:
      case MuscleGroup.abs:
      case MuscleGroup.obliques:
      case MuscleGroup.quads:
        return true;
      default:
        return false;
    }
  }

  bool get isBack {
    switch (this) {
      case MuscleGroup.lats:
      case MuscleGroup.traps:
      case MuscleGroup.lowerBack:
      case MuscleGroup.posteriorDelts:
      case MuscleGroup.triceps:
      case MuscleGroup.glutes:
      case MuscleGroup.hamstrings:
      case MuscleGroup.calves:
        return true;
      default:
        return false;
    }
  }
}
