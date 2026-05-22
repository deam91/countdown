/// Builds the system prompt + JSON schema for a ranking request.
///
/// The schema uses a single object shape with a discriminator (`kind`)
/// and nullable fields for kind-specific data. OpenAI's strict
/// `response_format: json_schema` requires every property to be in
/// `required`, so we mark optional fields as `[T, null]`.
abstract final class PromptBuilder {
  static String systemPrompt(int n) => '''
You are a ranking expert. The user will ask for a top-N list. You return EXACTLY $n items, sorted from WORST to BEST so that rank $n is first in the array and rank 1 is last — a countdown reveal.

For each item, choose the most appropriate `kind`:
- "place": real-world location (restaurant, beach, landmark, mountain, lake, region). Set `address` to a street address when one exists, otherwise to a "Region, Country" string (e.g. "Himalayas, Nepal/China"); set to null only if neither makes sense. Set `lat`/`lng` to real coordinates whenever the place can be pinpointed (most natural features and named locations can); null is allowed but should be the exception. Null `author`, `year`, `tagline`.
- "book": a book. Set `author`, optional `year`. Null `address`, `lat`, `lng`, `tagline`.
- "person": a real person (athlete, author, founder). Set `tagline` (one phrase). Null `address`, `lat`, `lng`, `author`, `year`.
- "generic": anything that doesn't fit the others. Null all the kind-specific fields.

Rules:
- `rank` is 1..$n (1 = best).
- `score` is 0..10, two decimals.
- `whyItRanks` is ONE sentence, max 100 characters, no period at the end — shown on the ranking list under the title.
- `details` is the long-form description shown on the dedicated detail screen. 2-4 sentences (200-450 characters total) covering what makes this item notable: context, distinguishing characteristics, and (if relevant) one specific concrete fact. Distinct from `whyItRanks` — do not just paraphrase. Plain prose, no markdown.
- `imageUrl`: ALWAYS null. The client fetches images separately from Wikipedia using the `title`. Do NOT attempt to provide an image URL — you have proven unreliable at this and we no longer ask.
- Pick titles that are unambiguous and likely to resolve to a Wikipedia page (real proper nouns rather than vague descriptions). The client searches Wikipedia by `title` to find each item's image.
- Return ONLY the JSON object, no preamble or commentary.
''';

  static Map<String, dynamic> schema(int n) => {
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          'items': {
            'type': 'array',
            'minItems': n,
            'maxItems': n,
            'items': _itemSchema,
          },
        },
        'required': ['items'],
      };

  static const Map<String, dynamic> _itemSchema = {
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'kind': {
        'type': 'string',
        'enum': ['place', 'book', 'person', 'generic'],
      },
      'rank': {'type': 'integer'},
      'title': {'type': 'string'},
      'whyItRanks': {'type': 'string'},
      'details': {'type': 'string'},
      'score': {'type': 'number'},
      'imageUrl': {
        'type': ['string', 'null'],
      },
      'address': {
        'type': ['string', 'null'],
      },
      'lat': {
        'type': ['number', 'null'],
      },
      'lng': {
        'type': ['number', 'null'],
      },
      'author': {
        'type': ['string', 'null'],
      },
      'year': {
        'type': ['integer', 'null'],
      },
      'tagline': {
        'type': ['string', 'null'],
      },
    },
    'required': [
      'kind',
      'rank',
      'title',
      'whyItRanks',
      'details',
      'score',
      'imageUrl',
      'address',
      'lat',
      'lng',
      'author',
      'year',
      'tagline',
    ],
  };

  /// Normalizes a user query for cache lookup: lowercased + whitespace
  /// collapsed. Two semantically identical queries hash to the same key.
  static String normalize(String query) =>
      query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
