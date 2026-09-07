/**
 * Side-effect-free Apex helpers for text normalization, list chunking, and integer clamping.
 * All methods are static. The private constructor prevents instantiation.
 */
public with sharing class DummyStoryHelper {
    private static final Integer DEFAULT_CLAMP = 0;

    /**
     * Prevents instantiation — use static methods only.
     */
    @TestVisible
    private DummyStoryHelper() {
    }

    /**
     * Converts a string to title case. Blank input returns an empty string.
     * Words are split on whitespace; each word is lowercased then capitalized.
     * @param value The string to normalize
     * @return Title-cased text, or an empty string when value is blank
     * @example
     * String titled = DummyStoryHelper.titleCase('hello WORLD'); // Hello World
     */
    public static String titleCase(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        List<String> titledWords = new List<String>();
        for (String word : value.normalizeSpace().split(' ')) {
            String lower = word.toLowerCase();
            titledWords.add(
                lower.substring(0, 1).toUpperCase() +
                (lower.length() > 1 ? lower.substring(1) : '')
            );
        }
        return String.join(titledWords, ' ');
    }

    /**
     * Splits a list into sublists of at most chunkSize elements.
     * Null, empty, or non-positive chunk sizes return an empty result.
     * @param items The list to chunk
     * @param chunkSize Maximum size of each chunk
     * @return A list of sublists, each containing up to chunkSize elements
     * @example
     * List<List<String>> chunks = DummyStoryHelper.chunkList(names, 200);
     */
    public static List<List<String>> chunkList(List<String> items, Integer chunkSize) {
        List<List<String>> chunks = new List<List<String>>();
        if (items == null || items.isEmpty() || chunkSize == null || chunkSize <= 0) {
            return chunks;
        }

        List<String> currentChunk = new List<String>();
        for (String item : items) {
            currentChunk.add(item);
            if (currentChunk.size() == chunkSize) {
                chunks.add(currentChunk);
                currentChunk = new List<String>();
            }
        }
        if (!currentChunk.isEmpty()) {
            chunks.add(currentChunk);
        }
        return chunks;
    }

    /**
     * Clamps an integer between optional min and max bounds.
     * A null value falls back to min, then max, then 0.
     * A missing bound is treated as unbounded on that side.
     * If min is greater than max, the bounds are swapped.
     * @param value The value to clamp
     * @param minValue Inclusive lower bound; null means no lower bound
     * @param maxValue Inclusive upper bound; null means no upper bound
     * @return The clamped integer
     * @example
     * Integer clamped = DummyStoryHelper.clampInteger(25, 0, 10); // 10
     */
    public static Integer clampInteger(Integer value, Integer minValue, Integer maxValue) {
        if (value == null) {
            return minValue ?? maxValue ?? DEFAULT_CLAMP;
        }

        Integer lower = minValue ?? value;
        Integer upper = maxValue ?? value;
        if (lower > upper) {
            Integer swapped = lower;
            lower = upper;
            upper = swapped;
        }

        if (value < lower) {
            return lower;
        }
        if (value > upper) {
            return upper;
        }
        return value;
    }
}
