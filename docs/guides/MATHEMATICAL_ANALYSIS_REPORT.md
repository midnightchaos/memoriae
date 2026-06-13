# mem3 — Algorithms & Pseudocode Reference

---

## 1. Chatbot — Voice Command Pipeline (Menta)

```text
FUNCTION processVoiceCommand(command)
    state = PROCESSING

    IF isNavigationCommand(command) THEN
        speak("Taking you to " + destination)
        RETURN
    END IF

    dbResult = queryDatabase(command)
    IF dbResult IS NOT NULL THEN
        speak(dbResult)
        RETURN
    END IF

    aiResponse = getAiResponse(command)
    speak(aiResponse)
    state = IDLE
END FUNCTION
```

**State Machine**: `idle → listening → processing → speaking → idle`
**Error Recovery**: Auto-reset to `idle` after 2s delay.

---

## 2. Gemini AI — Exponential Backoff Retry

$$\tau(n) = 2s \times 2^n + \text{rand}(0, 1000\text{ms})$$

```text
FUNCTION makeApiRequestWithRetry(url, body, maxRetries)
    attempt = 0
    WHILE attempt < maxRetries DO
        response = POST(url, body, timeout=30s)

        IF response.status == 200 THEN RETURN response
        IF response.status IN [429, 500, 503] THEN
            WAIT 2s * 2^attempt + random(0..1000ms)
            attempt++
        ELSE IF response.status IN [401, 403] THEN
            RETURN response  // Non-retryable
        END IF
    END WHILE
    THROW "All retries exhausted"
END FUNCTION
```

**LLM Parameters**: `temperature=0.7`, `topK=40`, `topP=0.95`, `maxOutputTokens=1024`

---

## 3. Breathing Therapy — Phase State Machine

**Circle Size**: $D_{outer}(t) = 100 + f(t) \times 150$, $D_{inner}(t) = 80 + f(t) \times 100$

| Pattern | Inhale | Hold | Exhale | Hold2 |
| :--- | :--- | :--- | :--- | :--- |
| 4-7-8 | 4s | 7s | 8s | — |
| Box | 4s | 4s | 4s | 4s |
| Simple | 4s | — | 4s | — |
| Deep Calm | 5s | 5s | 5s | — |

```text
FUNCTION runBreathingCycle(pattern)
    IF NOT isActive THEN RETURN
    animate(EXPAND, pattern.inhale)
    WAIT pattern.inhale

    IF pattern.hasHold THEN WAIT pattern.hold

    animate(SHRINK, pattern.exhale)
    WAIT pattern.exhale

    IF pattern.hasHold2 THEN WAIT pattern.hold2

    cycleCount++
    RECURSE runBreathingCycle(pattern)
END FUNCTION
```

---

## 4. Meditation — Progress & Phase Trigger

$$P = \frac{T_{remaining}}{T_{selected} \times 60} \quad \in [0.0, 1.0]$$

$$\text{minutes} = T_{remaining} \div 60, \quad \text{seconds} = T_{remaining} \bmod 60$$

$$\text{IF } (T_{remaining} \bmod 30 = 0) \implies \text{nextGuidanceStep()}$$

---

## 5. Medications — Scheduling & Filter

$$T_{next} = \begin{cases} T_{today} & \text{if } T_{today} > \text{now} \\ T_{today} + 1\text{ day} & \text{if } T_{today} \leq \text{now} \end{cases}$$

$$ID_{notif} = \text{medicationId.hashCode}$$

```text
FUNCTION applyFilters(medications, searchQuery, statusFilter)
    RETURN medications WHERE:
        (searchQuery IS EMPTY
            OR name CONTAINS searchQuery
            OR dosage CONTAINS searchQuery)
        AND
        (statusFilter == "all"
            OR (statusFilter == "active" AND isActive)
            OR (statusFilter == "inactive" AND NOT isActive))
END FUNCTION
```

---

## 6. Daily Routines — Weekday Recurrence

$$\Delta d = (D_{target} - D_{current}) \bmod 7$$
$$\text{IF } \Delta d = 0 \text{ AND time passed} \implies \Delta d = 7$$

$$ID_{notif} = \text{"\{routine.id\}\_\{day\}"}.hashCode$$

---

## 7. Safety Locations — Coordinate Projection

$$X_{screen} = (\lambda - \lambda_{ref}) \times 500 \quad \text{clamped to } [0, 400]$$
$$Y_{screen} = (\phi_{ref} - \phi) \times 500 \quad \text{clamped to } [0, 300]$$

**Geofence radius**: $R \in [50m, 500m]$ (9 discrete steps via slider)

---

## 8. Analytics — Engagement & Streaks

$$\bar{C}_{day} = \frac{C_{total}}{D_{account} + 1}, \quad \bar{C}_{week} = \bar{C}_{day} \times 7$$

$$E = 2C + 10J + 5G \quad (C=\text{Chats}, J=\text{Journals}, G=\text{Games})$$

$$\text{New Session IF: } \Delta T_{messages} > 30\text{ min}$$

```text
FUNCTION getLongestStreak(dates)
    dates = SORT_ASCENDING(UNIQUE(dates))
    maxStreak = 0, currentStreak = 1

    FOR i FROM 1 TO dates.length DO
        IF dates[i] - dates[i-1] == 1 day THEN
            currentStreak++
        ELSE
            maxStreak = MAX(maxStreak, currentStreak)
            currentStreak = 1
        END IF
    END FOR
    RETURN MAX(maxStreak, currentStreak)
END FUNCTION
```

```text
FUNCTION buildEngagementHistory(userId)
    history = []
    FOR i FROM 29 DOWN TO 0 DO
        date = TODAY - i days
        history.ADD({date, total: chats(date) + journals(date) + games(date)})
    END FOR
    RETURN history
END FUNCTION
```

---

## 9. Face Matching Game — Accuracy & Color

$$\eta = \frac{\text{score}}{\text{attempts} \times 10} \times 100\%$$

$$\text{gameSize} = \min(6, \max(3, |\text{faces}|))$$

$$\text{color}[i] = \text{palette}[i \bmod |\text{palette}|]$$

```text
FUNCTION checkMatch(faceIdx, nameIdx)
    attempts++
    IF gameFaces[faceIdx].name == namesArray[nameIdx] THEN
        score += 10
        matchedSet.ADD(faceIdx)
        IF matchedSet.size == gameSize THEN triggerWin()
    ELSE
        WAIT 500ms
        resetSelections()
    END IF
END FUNCTION
```

---

## 10. Encryption — AES-256 CBC

$$K = \{r_1 ... r_{32}\}, \quad IV = \{r_1 ... r_{16}\} \quad r_i \in [0, 255] \text{ (secure random)}$$

$$C_i = E_K(P_i \oplus C_{i-1}) \quad \text{(CBC mode)}$$
