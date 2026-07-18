# Autonomous Project Loop Kit — Ελληνικός οδηγός

Αυτό είναι το εξωτερικό loop που συμφωνήσαμε.

Ο Claude, ο Codex ή ο Cursor μπορεί να τελειώνει κάθε συνεδρία. Το `run-loop.ps1` παραμένει ενεργό, διαβάζει την αποθηκευμένη κατάσταση και καλεί νέο agent μέχρι:

- να ολοκληρωθούν και να επαληθευτούν όλες οι εργασίες,
- να εμφανιστεί πραγματικό εμπόδιο που απαιτεί άνθρωπο,
- να εξαντληθούν τα όρια χρόνου ή αποτυχιών,
- ή να δημιουργήσεις το `.loop/STOP`.

```text
run-loop.ps1
    ↓
επιλογή επόμενου READY task
    ↓
νέος agent με καθαρό context
    ↓
μία bounded εργασία
    ↓
status.json + tests
    ↓
ανεξάρτητοι έλεγχοι από τον runner
    ↓
DONE → επόμενο task
RETRY → νέα προσπάθεια
BLOCKED → ασφαλές σταμάτημα
κανένα task → completion audits
```

## Γιατί χρειάζονται και τα δύο

- `LOOPS.md`: το μόνιμο συμβόλαιο και οι κανόνες.
- `run-loop.ps1`: ο παλμός που καλεί ξανά νέο agent.

## Εγκατάσταση στο Socrates AI

```powershell
pwsh -NoProfile -File .\install-loop.ps1 `
  -TargetRepo "C:\Users\spirc\Desktop\Socrates-AI"
```

Ο installer:

- κρατά backup,
- δεν αντικαθιστά σιωπηρά τα υπάρχοντα αρχεία,
- προσθέτει managed block σε `AGENTS.md` και `CLAUDE.md`,
- προσθέτει Cursor rule,
- λέει στους agents να διαβάζουν το `LOOPS.md` μόνο όταν υπάρχει `.loop/ACTIVE`.

Μετά:

```powershell
cd C:\Users\spirc\Desktop\Socrates-AI
pwsh -NoProfile -File .\validate-loop.ps1
pwsh -NoProfile -File .\run-loop.ps1 -DryRun
pwsh -NoProfile -File .\run-loop.ps1 -Provider codex
```

## Πριν από πραγματικό unattended run

Ρύθμισε στο `loop.config.json`:

- provider sequence,
- μέγιστο χρόνο/iterations,
- global completion commands,
- protected paths,
- exact model IDs όταν χρειάζεται.

Το αρχικό backlog έχει planning-only bootstrap task. Ο πρώτος agent μπορεί να χτίσει το backlog από `PRESENT.md`, `PLANS.md`, `MEMORY.md`, README, tests και repository history. Δεν επιτρέπεται να αλλάξει source code στο bootstrap.

## Τι δεν κάνει από προεπιλογή

- Δεν κάνει push.
- Δεν κάνει merge.
- Δεν ανοίγει PR.
- Δεν δουλεύει πάνω στο `main`/`master`.
- Δεν δέχεται το `COMPLETE` του μοντέλου χωρίς gates.
- Δεν επιτρέπει αλλαγές στον loop control plane.
- Δεν θεωρεί ότι πέρασαν tests επειδή το είπε ο agent.

## Checkpoints χωρίς αυτόματο commit

Μετά από επιτυχημένο task αποθηκεύονται patch, αλλαγμένα αρχεία, διαγραφές, logs, status, backlog snapshot και receipt. Έτσι υπάρχει recovery evidence χωρίς αυτόματο commit/push/merge.

## Stop / resume

```powershell
pwsh -NoProfile -File .\stop-loop.ps1
pwsh -NoProfile -File .\run-loop.ps1 -ClearStop
```

Οι agents αλλάζουν και τερματίζουν. Η μνήμη, οι κανόνες, τα tasks, οι έλεγχοι και ο runner παραμένουν.
