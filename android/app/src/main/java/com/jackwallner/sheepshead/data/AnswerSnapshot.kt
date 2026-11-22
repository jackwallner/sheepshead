package com.jackwallner.sheepshead.data

/**
 * What the stores held for one item before it was graded. A flashcard "Undo
 * last answer" puts this back, so an undone answer leaves no attempt, streak,
 * review date or miss behind and answering again counts once.
 */
class AnswerSnapshot private constructor(
    val itemID: String,
    private val record: PracticeRecord?,
    private val mark: ProgressStore.ItemSnapshot,
) {
    fun restore(progress: ProgressStore, records: PracticeRecordStore) {
        records.restore(itemID, record)
        progress.restoreItem(mark)
    }

    companion object {
        fun take(progress: ProgressStore, records: PracticeRecordStore, itemID: String) =
            AnswerSnapshot(itemID, records.snapshot(itemID), progress.snapshotItem(itemID))
    }
}
