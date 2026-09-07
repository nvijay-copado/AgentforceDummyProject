/**
 * Tests DummyStoryHelper titleCase, chunkList, and clampInteger
 * for positive, null, empty, and bulk (251+) paths.
 */
@IsTest
private class DummyStoryHelperTest {
    private static final Integer BULK_SIZE = 251;
    private static final Integer CHUNK_SIZE = 50;

    @IsTest
    static void shouldTitleCaseWords_WhenMixedCaseInput() {
        Test.startTest();
        String actual = DummyStoryHelper.titleCase('  hello WORLD a from apex  ');
        Test.stopTest();

        Assert.areEqual('Hello World A From Apex', actual, 'Words should be title-cased and trimmed');
    }

    @IsTest
    static void shouldReturnEmpty_WhenTitleCaseNullInput() {
        Test.startTest();
        String actual = DummyStoryHelper.titleCase(null);
        Test.stopTest();

        Assert.areEqual('', actual, 'Null input should return an empty string');
    }

    @IsTest
    static void shouldReturnEmpty_WhenTitleCaseBlankInput() {
        Test.startTest();
        String actual = DummyStoryHelper.titleCase('   ');
        Test.stopTest();

        Assert.areEqual('', actual, 'Blank input should return an empty string');
    }

    @IsTest
    static void shouldChunkList_WhenValidInput() {
        List<String> items = new List<String>{ 'a', 'b', 'c', 'd', 'e' };

        Test.startTest();
        List<List<String>> chunks = DummyStoryHelper.chunkList(items, 2);
        Test.stopTest();

        Assert.areEqual(3, chunks.size(), 'Five items with size 2 should produce three chunks');
        Assert.areEqual(new List<String>{ 'a', 'b' }, chunks[0], 'First chunk should hold the first two items');
        Assert.areEqual(new List<String>{ 'c', 'd' }, chunks[1], 'Second chunk should hold the next two items');
        Assert.areEqual(new List<String>{ 'e' }, chunks[2], 'Last chunk should hold the remainder');
    }

    @IsTest
    static void shouldReturnEmptyChunks_WhenChunkListNullInput() {
        Test.startTest();
        List<List<String>> chunks = DummyStoryHelper.chunkList(null, 2);
        Test.stopTest();

        Assert.isTrue(chunks.isEmpty(), 'Null list should return no chunks');
    }

    @IsTest
    static void shouldReturnEmptyChunks_WhenChunkListEmptyInput() {
        Test.startTest();
        List<List<String>> chunks = DummyStoryHelper.chunkList(new List<String>(), 2);
        Test.stopTest();

        Assert.isTrue(chunks.isEmpty(), 'Empty list should return no chunks');
    }

    @IsTest
    static void shouldReturnEmptyChunks_WhenChunkSizeNull() {
        List<String> items = new List<String>{ 'a' };

        Test.startTest();
        List<List<String>> chunks = DummyStoryHelper.chunkList(items, null);
        Test.stopTest();

        Assert.isTrue(chunks.isEmpty(), 'Null chunk size should return no chunks');
    }

    @IsTest
    static void shouldReturnEmptyChunks_WhenChunkSizeZero() {
        List<String> items = new List<String>{ 'a' };

        Test.startTest();
        List<List<String>> chunks = DummyStoryHelper.chunkList(items, 0);
        Test.stopTest();

        Assert.isTrue(chunks.isEmpty(), 'Non-positive chunk size should return no chunks');
    }

    @IsTest
    static void shouldChunkList_WhenProcessing251() {
        List<String> items = new List<String>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            items.add('item-' + i);
        }
        Integer expectedChunks = (BULK_SIZE + CHUNK_SIZE - 1) / CHUNK_SIZE;

        Test.startTest();
        List<List<String>> chunks = DummyStoryHelper.chunkList(items, CHUNK_SIZE);
        Test.stopTest();

        Assert.areEqual(expectedChunks, chunks.size(), '251 items should split into the expected chunk count');
        Assert.areEqual(CHUNK_SIZE, chunks[0].size(), 'Full chunks should match the requested size');
        Assert.areEqual(1, chunks[chunks.size() - 1].size(), 'Remainder chunk should hold the leftover item');
        Assert.areEqual('item-0', chunks[0][0], 'First item should remain first after chunking');
        Assert.areEqual('item-250', chunks[chunks.size() - 1][0], 'Last item should land in the final chunk');
    }

    @IsTest
    static void shouldClampInteger_WhenValueInsideBounds() {
        Test.startTest();
        Integer actual = DummyStoryHelper.clampInteger(5, 0, 10);
        Test.stopTest();

        Assert.areEqual(5, actual, 'In-range values should be unchanged');
    }

    @IsTest
    static void shouldClampInteger_WhenValueBelowMin() {
        Test.startTest();
        Integer actual = DummyStoryHelper.clampInteger(-3, 0, 10);
        Test.stopTest();

        Assert.areEqual(0, actual, 'Values below min should clamp to min');
    }

    @IsTest
    static void shouldClampInteger_WhenValueAboveMax() {
        Test.startTest();
        Integer actual = DummyStoryHelper.clampInteger(25, 0, 10);
        Test.stopTest();

        Assert.areEqual(10, actual, 'Values above max should clamp to max');
    }

    @IsTest
    static void shouldUseMinFallback_WhenClampValueNull() {
        Test.startTest();
        Integer actual = DummyStoryHelper.clampInteger(null, 2, 10);
        Test.stopTest();

        Assert.areEqual(2, actual, 'Null value should fall back to min');
    }

    @IsTest
    static void shouldDefaultToZero_WhenClampAllNull() {
        Test.startTest();
        Integer actual = DummyStoryHelper.clampInteger(null, null, null);
        Test.stopTest();

        Assert.areEqual(0, actual, 'All-null clamp should return 0');
    }

    @IsTest
    static void shouldSwapBounds_WhenMinGreaterThanMax() {
        Test.startTest();
        Integer actual = DummyStoryHelper.clampInteger(50, 100, 0);
        Test.stopTest();

        Assert.areEqual(50, actual, 'Value inside swapped bounds should stay unchanged');
    }

    @IsTest
    static void shouldTreatMissingBoundAsUnbounded() {
        Test.startTest();
        Integer noMax = DummyStoryHelper.clampInteger(50, 0, null);
        Integer noMin = DummyStoryHelper.clampInteger(-5, null, 10);
        Test.stopTest();

        Assert.areEqual(50, noMax, 'Missing max should leave a value above min unchanged');
        Assert.areEqual(-5, noMin, 'Missing min should leave a value below max unchanged');
    }

    @IsTest
    static void shouldAllowPrivateConstructorForCoverage() {
        Test.startTest();
        DummyStoryHelper helper = new DummyStoryHelper();
        Test.stopTest();

        Assert.isNotNull(helper, 'Private constructor should be test-visible for coverage');
    }
}
