### Default implememtation

Resolution — used both when computing today's response doc and when previewing "what happens tomorrow":
typescriptfunction resolveDefault(entry: { active: any; pending?: { effectiveFrom: string } | null }, dateStr: string) {
  if (entry.pending && entry.pending.effectiveFrom <= dateStr) {
    const { effectiveFrom, ...value } = entry.pending;
    return value;
  }
  return entry.active;
}
Plug this into the resolveResponses from before in place of the raw defaults[id] lookup — nothing else about that flow changes.
The write path — this is where "collapse the pending into active" happens, lazily, at edit time, not on a schedule:
typescriptexport const updateDefault = onCall(async (req) => {
  const { driverId, tripId, leg, studentId, newValue } = req.data;
  const configRef = db.doc(`drivers/${driverId}/trips/${tripId}/config/${leg}_defaults`);
  const today = localDateString(/* driver's timezone */);
  const tomorrow = addDays(today, 1);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(configRef);
    const entry = snap.data()[studentId] as { active: any; pending?: any };

    // If a previous pending change has already come due, it's the new baseline.
    const active = (entry.pending && entry.pending.effectiveFrom <= today)
      ? { ...entry.pending, effectiveFrom: undefined }
      : entry.active;

    tx.update(configRef, {
      [`${studentId}.active`]: active,
      [`${studentId}.pending`]: { ...newValue, effectiveFrom: tomorrow },
    });
  });
  return { effectiveFrom: tomorrow };
});