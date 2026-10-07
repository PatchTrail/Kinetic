import 'dart:convert';
import 'dart:io';
import 'dart:math';

class QuoteItem {
  final String quote;
  final String author;
  final String? book;
  final String category;

  const QuoteItem({
    required this.quote,
    required this.author,
    this.book,
    this.category = 'motivation',
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      quote: json['quote'] as String? ?? 'Discipline is destiny.',
      author: json['author'] as String? ?? 'Unknown',
      book: json['book'] as String?,
      category: 'literature',
    );
  }
}

class QuoteService {
  static final QuoteService instance = QuoteService._internal();
  QuoteService._internal();

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3);

  // Curated offline athletic, stoic, and discipline manifesto quotes
  final List<QuoteItem> _preWorkoutQuotes = const [
    QuoteItem(
      quote: "The iron never lies to you. You can walk outside and listen to all kinds of talk, but two hundred pounds is always two hundred pounds.",
      author: "Henry Rollins",
      book: "The Iron and the Soul",
      category: "strength",
    ),
    QuoteItem(
      quote: "No citizen has a right to be an amateur in the matter of physical training. What a disgrace it is for a man to grow old without seeing the beauty and strength of which his body is capable.",
      author: "Socrates",
      book: "Xenophon's Memorabilia",
      category: "classical",
    ),
    QuoteItem(
      quote: "You have power over your mind - not outside events. Realize this, and you will find strength.",
      author: "Marcus Aurelius",
      book: "Meditations",
      category: "stoicism",
    ),
    QuoteItem(
      quote: "We don't rise to the level of our expectations, we fall to the level of our training.",
      author: "Archilochus",
      book: "Fragments",
      category: "discipline",
    ),
    QuoteItem(
      quote: "Don't count the days, make the days count. The pain you feel today will be the strength you feel tomorrow.",
      author: "Muhammad Ali",
      book: "The Soul of a Butterfly",
      category: "drive",
    ),
    QuoteItem(
      quote: "Discipline equals freedom. Put in the reps when nobody is watching.",
      author: "Jocko Willink",
      book: "Discipline Equals Freedom",
      category: "mindset",
    ),
    QuoteItem(
      quote: "The last three or four reps is what makes the muscle grow. This area of pain divides a champion from someone who is not a champion.",
      author: "Arnold Schwarzenegger",
      book: "The Education of a Bodybuilder",
      category: "hypertrophy",
    ),
    QuoteItem(
      quote: "First say to yourself what you would be; and then do what you have to do.",
      author: "Epictetus",
      book: "Discourses",
      category: "stoicism",
    ),
    QuoteItem(
      quote: "It's supposed to be hard. If it wasn't hard, everyone would do it. The hard is what makes it great.",
      author: "Tom Hanks",
      book: "A League of Their Own",
      category: "grit",
    ),
  ];

  final List<QuoteItem> _postWorkoutQuotes = const [
    QuoteItem(
      quote: "Victory is not won in miles but in inches. Win a little now, hold your ground, and later, win a little more.",
      author: "Louis L'Amour",
      book: "Education of a Wandering Man",
      category: "victory",
    ),
    QuoteItem(
      quote: "Small disciplines repeated with consistency every day lead to great achievements gained slowly over time.",
      author: "John C. Maxwell",
      book: "The 15 Invaluable Laws of Growth",
      category: "consistency",
    ),
    QuoteItem(
      quote: "I hated every minute of training, but I said, 'Don't quit. Suffer now and live the rest of your life as a champion.'",
      author: "Muhammad Ali",
      book: "Greatest of All Time",
      category: "champion",
    ),
    QuoteItem(
      quote: "Well done is better than well said. Another brick laid in the foundation.",
      author: "Benjamin Franklin",
      book: "Poor Richard's Almanack",
      category: "execution",
    ),
    QuoteItem(
      quote: "Nothing can withstand the force of an ongoing human will, when it is willing to stake its very existence to its purpose.",
      author: "Leo Tolstoy",
      book: "War and Peace",
      category: "willpower",
    ),
    QuoteItem(
      quote: "He who has a why to live can bear almost any how. Rest now, grow stronger tomorrow.",
      author: "Friedrich Nietzsche",
      book: "Twilight of the Idols",
      category: "recovery",
    ),
    QuoteItem(
      quote: "Today you proved what you are capable of. The standard has been set higher.",
      author: "David Goggins",
      book: "Can't Hurt Me",
      category: "relentless",
    ),
  ];

  final Random _rng = Random();

  /// Fetches a live quote from the recite-v2 API with robust fallback to curated athletic quotes
  Future<QuoteItem> fetchLiveOrFallbackQuote({bool isPostWorkout = false}) async {
    try {
      final request = await _httpClient
          .getUrl(Uri.parse('https://recite-flax.vercel.app/api/v1/random'))
          .timeout(const Duration(milliseconds: 2500));

      final response = await request.close().timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(body);
        if (data.containsKey('quote') && (data['quote'] as String).isNotEmpty) {
          final item = QuoteItem.fromJson(data);
          // If quote length is reasonable for HUD display (under 280 chars), use it
          if (item.quote.length <= 280) {
            return item;
          }
        }
      }
    } catch (_) {
      // Fallback silently to curated offline quotes
    }

    return isPostWorkout ? getRandomPostWorkoutQuote() : getRandomPreWorkoutQuote();
  }

  QuoteItem getRandomPreWorkoutQuote() {
    return _preWorkoutQuotes[_rng.nextInt(_preWorkoutQuotes.length)];
  }

  QuoteItem getRandomPostWorkoutQuote() {
    return _postWorkoutQuotes[_rng.nextInt(_postWorkoutQuotes.length)];
  }
}
