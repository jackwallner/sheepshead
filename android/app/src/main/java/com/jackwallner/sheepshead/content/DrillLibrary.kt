package com.jackwallner.sheepshead.content

import com.jackwallner.sheepshead.model.Room

object DrillLibrary {
    val rooms: List<Room> get() = SheepsheadContent.library.rooms

    fun room(id: String): Room? = rooms.firstOrNull { it.id == id }

    /** The room a drill belongs to, so drill screens can report per-room accuracy. */
    fun roomID(forDrillID: String): String =
        rooms.firstOrNull { room -> room.drills.any { it.id == forDrillID } }?.id ?: ""
}

object HowToPlayContent {
    val pages: List<HowToPlayPage> get() = SheepsheadContent.library.primer

    /** The room recommended at the end of the primer for an onboarding skill level. */
    fun recommendedRoom(skillLevel: String): Room {
        val roomID = when (skillLevel) {
            "basics" -> "trump-room"
            "played" -> "trick-room"
            else -> "card-room"
        }
        return DrillLibrary.room(roomID) ?: DrillLibrary.rooms.first()
    }
}
