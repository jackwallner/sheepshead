package com.jackwallner.sheepshead

import com.jackwallner.sheepshead.model.PlayingCard
import org.json.JSONArray
import org.json.JSONObject

/** The iOS output recorded in `sheepshead-parity.json` by `scripts/sync-android-content.sh`. */
object ParityFixtures {
    val json: JSONObject by lazy {
        val stream = javaClass.classLoader!!.getResourceAsStream("sheepshead-parity.json")!!
        JSONObject(stream.bufferedReader().use { it.readText() })
    }
}

fun JSONArray.strings() = (0 until length()).map { getString(it) }
fun JSONArray.ints() = (0 until length()).map { getInt(it) }
fun JSONArray.objects() = (0 until length()).map { getJSONObject(it) }
fun JSONArray.cards() = strings().map(PlayingCard::fromCode)
fun codes(cards: List<PlayingCard>) = cards.map { it.code }
