package com.jackwallner.sheepshead

import android.content.Intent
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** The first-run path, the free drills, and the paid boundary, on a real device. */
@RunWith(AndroidJUnit4::class)
class AppFlowTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private var scenario: ActivityScenario<MainActivity>? = null

    private fun launch(onboarded: Boolean, forcePro: Boolean = false, skill: String? = null) {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(context, MainActivity::class.java)
            .putExtra("resetAll", true)
            .putExtra("uiTest", true)
            .putExtra("onboarded", onboarded)
            .putExtra("forcePro", forcePro)
            .putExtra("appearance", "light")
        skill?.let { intent.putExtra("skillLevel", it) }
        scenario = ActivityScenario.launch(intent)
    }

    @After
    fun tearDown() {
        scenario?.close()
    }

    private fun waitFor(text: String, timeout: Long = 30_000) {
        compose.waitUntil(timeout) {
            compose.onAllNodes(hasText(text, substring = true) or hasContentDescription(text) or hasTestTag(text))
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /** Waits until exactly one node carries [tag] (transitions briefly show two), then taps it. */
    private fun tag(tag: String) {
        compose.waitUntil(15_000) { compose.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().size == 1 }
        runCatching { compose.onNodeWithTag(tag).performScrollTo() }
        compose.onNodeWithTag(tag).performClick()
        compose.waitForIdle()
    }

    @Test
    fun reviewerAccessIsMaskedRejectsWrongCodeAndPersists() = runBlocking {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val code = checkNotNull(InstrumentationRegistry.getArguments().getString("reviewCode")) { "Supply the private reviewer code through the local redacting harness." }
        launch(onboarded = true)
        waitFor("Settings")
        compose.onNode(hasContentDescription("Settings")).performClick()
        compose.onNodeWithTag("version-row").performScrollTo().performTouchInput { longClick() }
        val field = compose.onNodeWithTag("reviewer-code")
        field.assert(SemanticsMatcher.keyIsDefined(SemanticsProperties.Password))
        field.performTextInput("wrong")
        tag("reviewer-unlock")
        compose.onNode(hasText("That code isn't valid.")).assertIsDisplayed()
        val app = instrumentation.targetContext.applicationContext as SheepsheadApplication
        assertFalse(app.graph.subscriptions.isPro)
        field.performTextClearance()
        field.performTextInput(code)
        tag("reviewer-unlock")
        assertTrue(app.graph.subscriptions.isPro)
        app.graph.subscriptions.refreshCustomerInfo(fetchCurrent = true)
        assertTrue(app.graph.subscriptions.isPro)
        assertTrue(AppGraph(app).subscriptions.isPro)
    }

    @Test
    fun onboardingSoftExitLandsOnHomeThroughTheTour() {
        launch(onboarded = false)
        waitFor("Make it stick between games")
        repeat(3) { tag("onboarding-primary") }
        tag("skill-played")
        tag("onboarding-primary")
        waitFor("Get Started") // the trial page; its title depends on Play eligibility
        tag("soft-exit")
        waitFor("Four rooms, four skills")
        tag("tour-skip")
        waitFor("Your seat at the table.")
    }

    /** Answers the first choice until the drill reports its score. */
    private fun answerUntilScored(limit: Int = 40) {
        repeat(limit) {
            if (compose.onAllNodes(hasTestTag("drill-score")).fetchSemanticsNodes().isNotEmpty()) return
            tag("choice-0")
            waitFor("explanation")
            tag("next")
        }
        waitFor("drill-score")
    }

    @Test
    fun freeQuizGradesAndFinishes() {
        launch(onboarded = true)
        tag("room-card-room")
        tag("drill-card-quiz")
        answerUntilScored()
        tag("drill-done")
        waitFor("The Card Room")
    }

    @Test
    fun buryDrillTakesTwoCardsAndCoaches() {
        launch(onboarded = true)
        tag("room-bury-room")
        tag("drill-bury-two")
        tag("hand-card-0")
        tag("hand-card-1")
        tag("discard")
        waitFor("coach-headline")
        waitFor("Coach would bury:")
    }

    @Test
    fun lockedModesOpenThePaywallForFreePlayers() {
        launch(onboarded = true)
        tag("tile-endless")
        waitFor("Get Sheepshead+")
        waitFor("Restore")
        waitFor("Terms of Use")
        waitFor("Privacy Policy")
    }

    @Test
    fun membersReachEndlessPractice() {
        launch(onboarded = true, forcePro = true)
        tag("tile-endless")
        tag("skill-handReading")
        waitFor("ENDLESS PRACTICE")
        tag("choice-0")
        waitFor("explanation")
    }

    @Test
    fun membersRunTheSheepsheadMinute() {
        launch(onboarded = true, forcePro = true)
        tag("tile-minute")
        tag("start-minute")
        repeat(5) {
            tag("choice-0")
            waitFor("explanation")
            tag("next")
        }
        waitFor("minute-score")
        waitFor("BY SKILL")
    }
}
