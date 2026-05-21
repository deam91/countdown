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
- "place": real-world location (restaurant, beach, landmark). Set `address`, `lat`, `lng`. Null `author`, `year`, `tagline`.
- "book": a book. Set `author`, optional `year`. Null `address`, `lat`, `lng`, `tagline`.
- "person": a real person (athlete, author, founder). Set `tagline` (one phrase). Null `address`, `lat`, `lng`, `author`, `year`.
- "generic": anything that doesn't fit the others. Null all the kind-specific fields.

Rules:
- `rank` is 1..$n (1 = best).
- `score` is 0..10, two decimals.
- `whyItRanks` is ONE sentence, max 100 characters, no period at the end.
- `imageUrl` MUST be a publicly-accessible HTTPS image URL that visually represents this item:
  - For books: cover image (Open Library covers like `https://covers.openlibrary.org/b/isbn/<isbn>-L.jpg`, Wikipedia, Goodreads CDN, or the publisher).
  - For people: portrait or representative photo (Wikipedia Commons preferred, e.g. `https://upload.wikimedia.org/wikipedia/commons/...`).
  - For places: a recognizable photo of the location (Wikipedia Commons, official tourism sites).
  - For generic items: a relevant photo (Wikipedia Commons preferred).
  Prefer Wikipedia Commons URLs because they are stable and CORS-friendly. Never invent paths — if you are not confident a URL exists, use null.
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
