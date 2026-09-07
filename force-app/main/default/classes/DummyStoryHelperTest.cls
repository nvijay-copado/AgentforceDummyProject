@IsTest
private class DummyStoryHelperTest {

    @IsTest
    static void formatGreeting_returnsGuestForBlankName() {
        Assert.areEqual('Hello, Guest!', DummyStoryHelper.formatGreeting(null));
        Assert.areEqual('Hello, Guest!', DummyStoryHelper.formatGreeting('   '));
    }

    @IsTest
    static void formatGreeting_trimsAndFormatsName() {
        Assert.areEqual(
            'Hello, Salesforce!',
            DummyStoryHelper.formatGreeting('  Salesforce  ')
        );
    }

    @IsTest
    static void sumIntegers_handlesNullAndEmptyValues() {
        Assert.areEqual(0, DummyStoryHelper.sumIntegers(null));
        Assert.areEqual(0, DummyStoryHelper.sumIntegers(new List<Integer>()));
    }

    @IsTest
    static void sumIntegers_addsProvidedValues() {
        List<Integer> values = new List<Integer>{ 1, 2, null, 3 };
        Assert.areEqual(6, DummyStoryHelper.sumIntegers(values));
    }

    @IsTest
    static void isEven_identifiesEvenNumbers() {
        Assert.isTrue(DummyStoryHelper.isEven(4));
        Assert.isFalse(DummyStoryHelper.isEven(5));
        Assert.isFalse(DummyStoryHelper.isEven(null));
    }
}
