import 'package:flutter/material.dart';
import 'recipe.dart';

enum AiFollowUpType {
  accentColor,
  recipeRecommendation,
  ingredientConfirmation,
  generalOptions,
}

class AiActionCardItem {
  final String id;
  final String title;
  final String? subtitle;
  final Color? color;
  final IconData? icon;
  final Recipe? recipe;
  final String? badgeText;
  final bool isSelected;
  final Map<String, dynamic>? metadata;

  const AiActionCardItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.color,
    this.icon,
    this.recipe,
    this.badgeText,
    this.isSelected = false,
    this.metadata,
  });

  AiActionCardItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    Color? color,
    IconData? icon,
    Recipe? recipe,
    String? badgeText,
    bool? isSelected,
    Map<String, dynamic>? metadata,
  }) {
    return AiActionCardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      recipe: recipe ?? this.recipe,
      badgeText: badgeText ?? this.badgeText,
      isSelected: isSelected ?? this.isSelected,
      metadata: metadata ?? this.metadata,
    );
  }
}

class AiFollowUpSession {
  final String id;
  final String title;
  final String question;
  final AiFollowUpType type;
  final List<AiActionCardItem> actionCards;
  final List<String> quickReplies;
  final bool isCollapsed;

  const AiFollowUpSession({
    required this.id,
    required this.title,
    required this.question,
    required this.type,
    this.actionCards = const [],
    this.quickReplies = const [],
    this.isCollapsed = false,
  });

  AiFollowUpSession copyWith({
    String? id,
    String? title,
    String? question,
    AiFollowUpType? type,
    List<AiActionCardItem>? actionCards,
    List<String>? quickReplies,
    bool? isCollapsed,
  }) {
    return AiFollowUpSession(
      id: id ?? this.id,
      title: title ?? this.title,
      question: question ?? this.question,
      type: type ?? this.type,
      actionCards: actionCards ?? this.actionCards,
      quickReplies: quickReplies ?? this.quickReplies,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }
}
