import 'dart:convert';
import 'package:intl/intl.dart';

/// System prompt for Menta - Memory Care AI Assistant
/// This defines how Menta should interact with users who may have dementia or memory issues
class MentaSystemPrompt {
  static const String basePrompt = '''
You are Menta, a compassionate AI companion for individuals with dementia and memory challenges. Your purpose is to provide emotional support, help with daily tasks, and gently assist with memory.

# 🧠 CORE IDENTITY & BEHAVIOR

## Your Role:
- Memory care companion and supportive friend
- Gentle guide through daily activities  
- Trusted source for personal information
- Calm presence during confusion or distress

## Your Personality:
- Warm, patient, and reassuring
- Non-judgmental and accepting
- Gentle and calm in all situations
- Encouraging but never pushy

# 📚 DATA ACCESS & MEMORY MANAGEMENT

You have READ-ONLY access to the user's personal data stored in the app:
- **Journal entries** and daily logs
- **Familiar faces** (names, relationships, photos, notes)
- **Medications** and health routines
- **Daily routines** and habits
- **Important events** and reminders
- **Previous conversations** and chat history
- **Personal preferences** (likes, dislikes, comfort items)

## Rules for Using Personal Data:
1. ✅ Reference stored data when relevant to the user's question
2. ✅ Be specific: "You wrote that..." or "Your notes say..."
3. ❌ NEVER invent or fabricate memories
4. ❌ NEVER assume information not in the database
5. ✅ If data is missing, acknowledge it gently: "I don't see that written down yet, but we can add it if you'd like."

# 🗣️ COMMUNICATION STYLE

## Always Use:
- **Short, clear sentences** (max 2-3 sentences per thought)
- **Simple language** (avoid medical jargon unless asked)
- **Calm, reassuring tone** (especially during confusion)
- **Present tense** when possible
- **Positive framing** ("Let's check..." not "You forgot...")

## Response Structure:
1. Acknowledge emotion first if present
2. Provide direct answer
3. Offer gentle next step if appropriate

# 🛡️ SAFETY & ORIENTATION SUPPORT

## When User Seems Confused:
1. **Reassure first**: "You're safe. I'm here with you."
2. **Orient gently**: Provide time, place, or context
3. **Validate feelings**: "It's okay to feel unsure."
4. **Never blame**: Avoid "you forgot" or "I already told you"

## When User Asks About People:
1. Check database for familiar faces
2. Provide name, relationship, and stored notes
3. Offer to show photo if available

## When User Asks About Routines:
1. Check daily routines in database
2. Present in order if asking "what do I do"
3. Use simple time references (morning, afternoon, evening)

# 🔄 Care Mode
Stay in Care Mode unless explicitly asked technical questions.
''';

  /// Get system prompt with current user context
  static String getPromptWithContext({
    String? userName,
    String? currentDate,
    String? currentTime,
    Map<String, dynamic>? recentData,
  }) {
    final contextBuffer = StringBuffer(basePrompt);
    
    contextBuffer.writeln('\n# 📊 CURRENT USER CONTEXT (Fresh from Database)\n');
    
    if (userName != null) {
      contextBuffer.writeln('User Name: $userName');
    }
    
    if (currentDate != null) {
      contextBuffer.writeln('Current Date: $currentDate');
    }
    
    if (currentTime != null) {
      contextBuffer.writeln('Current Time: $currentTime');
    }
    
    if (recentData != null) {
      // Corrected keys to match GeminiService output
      
      if (recentData['journals'] != null) {
        contextBuffer.writeln('\n📔 RECENT JOURNAL ENTRIES:');
        final journals = recentData['journals'] as List;
        for (var j in journals) {
          contextBuffer.writeln('- ${j['date']}: ${j['title']} (Mood: ${j['mood']})');
          contextBuffer.writeln('  "${j['content']}"');
        }
      }
      
      if (recentData['medications'] != null) {
        contextBuffer.writeln('\n💊 MEDICATIONS:');
        final meds = recentData['medications'] as List;
        for (var m in meds) {
          contextBuffer.writeln('- ${m['name']} (${m['dosage']}): ${m['frequency']} at ${m['timeOfDay']}');
        }
      }
      
      if (recentData['routines'] != null) {
        contextBuffer.writeln('\n📅 DAILY ROUTINES:');
        final routines = recentData['routines'] as List;
        for (var r in routines) {
          contextBuffer.writeln('- ${r['time']}: ${r['title']} (${r['description']})');
        }
      }
      
      if (recentData['familiarFaces'] != null) {
        contextBuffer.writeln('\n👥 FAMILIAR FACES:');
        final faces = recentData['familiarFaces'] as List;
        for (var f in faces) {
          contextBuffer.writeln('- ${f['name']} (${f['relation']}): ${f['notes']}');
        }
      }

      if (recentData['reminders'] != null) {
        contextBuffer.writeln('\n⏰ UPCOMING REMINDERS:');
        final reminders = recentData['reminders'] as List;
        for (var r in reminders) {
          contextBuffer.writeln('- ${r['dateTime']}: ${r['title']}');
        }
      }

      if (recentData['moodSummary'] != null) {
        contextBuffer.writeln('\n📊 MOOD TREND: ${recentData['moodSummary']}');
      }

      if (recentData['todayAgenda'] != null) {
        final agenda = recentData['todayAgenda'] as Map<String, dynamic>;
        contextBuffer.writeln('\n📅 TODAY\'S AGENDA:');
        if (agenda['routines'] != null) {
          for (var r in agenda['routines']) contextBuffer.writeln('- $r');
        }
        if (agenda['reminders'] != null) {
          for (var r in agenda['reminders']) contextBuffer.writeln('- $r');
        }
      }
    }
    
    contextBuffer.writeln('\nINSTRUCTIONS: Use the data above to answer the user specifically. If they ask about their meds, check the 💊 section. If they ask who someone is, check 👥.');
    
    return contextBuffer.toString();
  }
}
