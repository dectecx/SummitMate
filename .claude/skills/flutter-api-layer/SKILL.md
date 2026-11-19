---
name: flutter-api-layer
description: Standardizes Flutter API layer development using Retrofit, Freezed, UTC DateTime converters, and Mappers for architecture decoupling and type safety.
---

# Flutter API Layer Architecture & Standards

## Overview

This skill defines standards for the Flutter network and API data layer, ensuring strong separation between external transport DTOs and internal domain entities using `Retrofit`, `Dio`, and `Freezed`.

## Architecture Rules

1. **Layer Separation**: Presentation and Domain layers must never import or reference API DTOs (`data/api/models/`). All communication flows through Domain entities.
2. **Strict Type Safety**: Do not parse `Map<String, dynamic>` manually. All network payloads must deserialize via Freezed-generated `fromJson` factories.
3. **Mapper Requirement**: API DTOs must be transformed into Domain models (and vice versa) exclusively via dedicated Mapper classes in `data/api/mappers/`.
4. **Dependency Injection**: API service interfaces must be registered as lazy singletons in `core/di/api_module.dart`.
5. **No Direct Remote Calls in UI/Cubits**: All network operations must pass through domain repositories.

## DateTime Serialization Policy

All date and time fields must use dedicated converters from `lib/data/api/converters/datetime_converter.dart`:

| Field Semantic | OpenAPI Format | Converter Annotation | Serialization Rule |
| :--- | :--- | :--- | :--- |
| Mandatory datetime | `date-time` | `@DateTimeUtcConverter()` | Persisted/transmitted in UTC ISO 8601; converted to local time in UI presentation |
| Nullable datetime | `date-time` | `@NullableDateTimeUtcConverter()` | Same as above, allows `null` |
| Mandatory date-only | `date` | `@DateOnlyConverter()` | Formatted as `YYYY-MM-DD`, timezone-agnostic |
| Nullable date-only | `date` | `@NullableDateOnlyConverter()` | Same as above, allows `null` |

### Code Example

```dart
// ✅ Correct
@freezed
class TripDto with _$TripDto {
  const factory TripDto({
    required String id,
    required String title,
    @JsonKey(name: 'created_at') @DateTimeUtcConverter() required DateTime createdAt,
    @JsonKey(name: 'start_date') @DateOnlyConverter() required DateTime startDate,
  }) = _TripDto;

  factory TripDto.fromJson(Map<String, dynamic> json) => _$TripDtoFromJson(json);
}

// ❌ Incorrect: Raw DateTime does not handle UTC conversion guarantees
@JsonKey(name: 'created_at') required DateTime createdAt,
```

## Implementation Workflow

1. **DTO Definition (`data/api/models/`)**: Define Freezed data classes matching backend JSON contracts.
2. **Service Definition (`data/api/services/`)**: Declare Retrofit HTTP endpoints with appropriate HTTP methods and headers.
3. **Mapper Implementation (`data/api/mappers/`)**: Implement bidirectional static mapping methods between DTOs and Domain entities.
4. **DI Registration (`core/di/api_module.dart`)**: Register the new Retrofit service in the Injectable module.
5. **Data Source Integration**: Inject the service into `RemoteDataSource` and use Mappers to produce domain objects.
6. **Code Generation**: Run `dart run build_runner build --delete-conflicting-outputs`.

## Verification Checklist

- DTO classes are strictly confined to `data/` and not imported in `presentation/` or `domain/`.
- `RemoteDataSource` depends on generated Retrofit API services rather than making raw `Dio` calls.
- Unit tests verify conversion edge cases (e.g., nullability, timezone conversions).
