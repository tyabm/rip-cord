import '../domain/models.dart';
import 'bonus_seed.dart';

/// Bump when replacing the full built-in set for existing installs.
/// v3: adds bonus (Mindfulness / Creative / Writing / Values) unlock prompts.
const int currentResponseLibraryVersion = 3;

/// Built-in library (~100). IDs are stable (`seed_…`) for merge/upgrade.
///
/// Design rule: each prompt should be completable in about **15–30 seconds**.
List<CompetingResponse> defaultCompetingResponses() {
  final items = <({
    String id,
    String category,
    String phrase,
    String action,
  })>[
    // ════════ Breathing / autonomic (~20) ════════
    (
      id: 'seed_box_breathing',
      category: 'Breathing',
      phrase: 'Slow the body; the urge will follow.',
      action: 'Box breathing: inhale 4, hold 4, exhale 4, hold 4 — one full box.',
    ),
    (
      id: 'seed_paced_breathing',
      category: 'Breathing',
      phrase: 'Longer exhales signal safety to the nervous system.',
      action: 'Paced breathing: inhale 4 counts, exhale 6 counts, three times.',
    ),
    (
      id: 'seed_physiological_sigh',
      category: 'Breathing',
      phrase: 'A double inhale can reset arousal quickly.',
      action:
          'Physiological sigh: two short nose inhales, one long mouth exhale. Repeat once.',
    ),
    (
      id: 'seed_pmr_shoulders',
      category: 'Breathing',
      phrase: 'Release stored tension in one place.',
      action: 'Tense shoulders 5 seconds, then drop and soften for 10.',
    ),
    (
      id: 'seed_pmr_hands',
      category: 'Breathing',
      phrase: 'Hands unclench; attention returns to the body.',
      action: 'Tight fists 5 seconds, open slowly, notice warmth for a few breaths.',
    ),
    (
      id: 'seed_pmr_jaw',
      category: 'Breathing',
      phrase: 'Unclench the face; unclench the urge.',
      action: 'Gently tense jaw 5 seconds, release, let tongue rest easy.',
    ),
    (
      id: 'seed_pmr_legs',
      category: 'Breathing',
      phrase: 'Ground tension, then let it go.',
      action: 'Press feet into floor 5 seconds, release, feel heaviness.',
    ),
    (
      id: 'seed_exhale_longer',
      category: 'Breathing',
      phrase: 'Exhale is the brake pedal.',
      action: 'Three breaths: inhale 3, exhale 6 (or as long as comfortable).',
    ),
    (
      id: 'seed_humming_exhale',
      category: 'Breathing',
      phrase: 'Vibration settles the system.',
      action: 'Inhale gently; hum on the exhale for one full breath, twice.',
    ),
    (
      id: 'seed_478_short',
      category: 'Breathing',
      phrase: 'A short 4-7-8 cycle is enough.',
      action: 'Inhale 4, hold 7, exhale 8 — once only if hold is hard, shorten holds.',
    ),
    (
      id: 'seed_coherent_breath',
      category: 'Breathing',
      phrase: 'Even rhythm, quieter mind.',
      action: 'Breathe in 5, out 5, for four cycles.',
    ),
    (
      id: 'seed_hand_on_chest',
      category: 'Breathing',
      phrase: 'Feel the breath, not the feed.',
      action: 'Hand on chest or belly; track three full rises and falls.',
    ),
    (
      id: 'seed_cold_water_face',
      category: 'Breathing',
      phrase: 'A quick sensory reset.',
      action: 'Splash cool water on face or wrists, or hold a cool object 15s.',
    ),
    (
      id: 'seed_sigh_out_loud',
      category: 'Breathing',
      phrase: 'Let the body complete a reset breath.',
      action: 'One big inhale and an audible long sigh out. Repeat once.',
    ),
    (
      id: 'seed_nostril_soft',
      category: 'Breathing',
      phrase: 'Soft nose breathing calms the pace.',
      action: 'Mouth closed; five slow nose breaths, jaw loose.',
    ),
    (
      id: 'seed_count_backwards_breath',
      category: 'Breathing',
      phrase: 'Counting crowds out the urge script.',
      action: 'Breathe out counting 10 down to 1 (one number per exhale or two).',
    ),
    (
      id: 'seed_shoulder_drop_breath',
      category: 'Breathing',
      phrase: 'Drop the shoulders with every exhale.',
      action: 'Four breaths: on each exhale, deliberately lower shoulders.',
    ),
    (
      id: 'seed_lip_blow',
      category: 'Breathing',
      phrase: 'Slow the outflow.',
      action: 'Inhale nose; exhale through pursed lips for a long count, three times.',
    ),
    (
      id: 'seed_resting_tongue',
      category: 'Breathing',
      phrase: 'Tiny body cues, big state change.',
      action: 'Rest tongue on roof of mouth; three quiet breaths.',
    ),
    (
      id: 'seed_ocean_breath_soft',
      category: 'Breathing',
      phrase: 'Soft sound, soft nervous system.',
      action: 'Slight throat constriction; whispery ocean exhale, three cycles.',
    ),

    // ════════ Grounding / sensory (~20) ════════
    (
      id: 'seed_five_color',
      category: 'Grounding',
      phrase: 'Orient to the room, not the feed.',
      action: 'Name 5 things you can see that are the same color.',
    ),
    (
      id: 'seed_four_sounds',
      category: 'Grounding',
      phrase: 'Sound pulls attention into the present.',
      action: 'Name 4 distinct things you can hear right now.',
    ),
    (
      id: 'seed_one_taste',
      category: 'Grounding',
      phrase: 'One sense is enough to interrupt the loop.',
      action: 'Notice 1 taste or mouth sensation (or sip water and name it).',
    ),
    (
      id: 'seed_hands_feet_20s',
      category: 'Grounding',
      phrase: 'Sensation is data; the urge is temporary.',
      action: 'Feel hands or feet for ~20 seconds: pressure, temperature, texture.',
    ),
    (
      id: 'seed_trace_object',
      category: 'Grounding',
      phrase: 'Detail crowds out automatic checking.',
      action: 'Trace an object’s outline; name 3 attributes (shape, color, texture).',
    ),
    (
      id: 'seed_54321_short',
      category: 'Grounding',
      phrase: 'Five senses, one short pass.',
      action: 'Name 5 see, 4 touch, 3 hear, 2 smell, 1 taste — briefly.',
    ),
    (
      id: 'seed_name_blue',
      category: 'Grounding',
      phrase: 'Hunt for blue instead of the screen.',
      action: 'Find and silently name 4 blue (or any color) items nearby.',
    ),
    (
      id: 'seed_temperature_scan',
      category: 'Grounding',
      phrase: 'Temperature is always available.',
      action: 'Notice coolest and warmest spot on your body for 15 seconds.',
    ),
    (
      id: 'seed_feet_edges',
      category: 'Grounding',
      phrase: 'Edges of contact = here and now.',
      action: 'Feel heels, balls, toes against the floor; shift weight slowly twice.',
    ),
    (
      id: 'seed_texture_inventory',
      category: 'Grounding',
      phrase: 'Texture beats abstraction.',
      action: 'Touch 3 textures (fabric, wood, metal) and name each.',
    ),
    (
      id: 'seed_window_light',
      category: 'Grounding',
      phrase: 'Light is a real-world anchor.',
      action: 'Look toward a window or lamp; describe the light quality in 3 words.',
    ),
    (
      id: 'seed_smell_nearby',
      category: 'Grounding',
      phrase: 'Smell is a fast interrupt.',
      action: 'Notice any scent (soap, coffee, air); if none, sniff a sleeve or lotion.',
    ),
    (
      id: 'seed_count_objects',
      category: 'Grounding',
      phrase: 'Numbers give the mind a job.',
      action: 'Count 8 objects of one type (corners, plants, books, cords).',
    ),
    (
      id: 'seed_left_right_name',
      category: 'Grounding',
      phrase: 'Spatial naming pulls you into the room.',
      action: 'Name 3 things left of you, then 3 things right of you.',
    ),
    (
      id: 'seed_press_palms',
      category: 'Grounding',
      phrase: 'Pressure is grounding.',
      action: 'Press palms together hard for 10 seconds, release, notice the tingle.',
    ),
    (
      id: 'seed_describe_chair',
      category: 'Grounding',
      phrase: 'Ordinary objects are enough.',
      action: 'Describe the chair or floor under you in one detailed sentence.',
    ),
    (
      id: 'seed_blink_slow',
      category: 'Grounding',
      phrase: 'Eyes rest; urge softens.',
      action: 'Soft gaze or closed eyes; 5 slow blinks if open, then reopen gently.',
    ),
    (
      id: 'seed_name_materials',
      category: 'Grounding',
      phrase: 'What is this made of?',
      action: 'Name materials of 5 nearby surfaces (plastic, cotton, glass…).',
    ),
    (
      id: 'seed_far_near_focus',
      category: 'Grounding',
      phrase: 'Change focus distance; change state.',
      action: 'Focus far object 5s, near object 5s; switch three times.',
    ),
    (
      id: 'seed_body_outline',
      category: 'Grounding',
      phrase: 'You have a body in a place.',
      action: 'Mentally outline head → shoulders → hips → feet, one breath each.',
    ),

    // ════════ Movement (~20) ════════
    (
      id: 'seed_calf_raises',
      category: 'Movement',
      phrase: 'Move the body; break the reach for the phone.',
      action: 'Do 10–20 slow calf raises.',
    ),
    (
      id: 'seed_overhead_stretch',
      category: 'Movement',
      phrase: 'Open the chest; change posture, change state.',
      action: 'Reach overhead, tall spine, long exhale — twice.',
    ),
    (
      id: 'seed_side_bend',
      category: 'Movement',
      phrase: 'A small motion is still a competing response.',
      action: 'Side bend left and right once each, slow and controlled.',
    ),
    (
      id: 'seed_gentle_twist',
      category: 'Movement',
      phrase: 'Unstick the spine from the scroll posture.',
      action: 'Gentle standing twist: look over each shoulder once, easy range.',
    ),
    (
      id: 'seed_leave_room',
      category: 'Movement',
      phrase: 'Change place, change the cue stack.',
      action: 'Walk out of the room — or step outdoors if you can — then return.',
    ),
    (
      id: 'seed_march_in_place',
      category: 'Movement',
      phrase: 'Legs moving beats thumbs scrolling.',
      action: 'March in place for ~20 seconds, arms swinging lightly.',
    ),
    (
      id: 'seed_wall_push',
      category: 'Movement',
      phrase: 'Push energy into something solid.',
      action: 'Push into a wall for 10 seconds, then release and shake arms.',
    ),
    (
      id: 'seed_shoulder_rolls',
      category: 'Movement',
      phrase: 'Roll out the phone hunch.',
      action: '5 slow shoulder rolls backward, then 5 forward.',
    ),
    (
      id: 'seed_neck_ease',
      category: 'Movement',
      phrase: 'Ease the neck without forcing.',
      action: 'Ear toward shoulder each side (gentle), then chin nods twice.',
    ),
    (
      id: 'seed_arm_circles',
      category: 'Movement',
      phrase: 'Big circles, small time.',
      action: 'Small arm circles 10 each direction (or one arm if space is tight).',
    ),
    (
      id: 'seed_sit_to_stand',
      category: 'Movement',
      phrase: 'Stand up; the urge loses its seat.',
      action: 'Stand if sitting; sit if standing — then reverse once more.',
    ),
    (
      id: 'seed_heel_to_toe',
      category: 'Movement',
      phrase: 'Balance demands attention.',
      action: 'Heel-to-toe steps in a line for 8–10 steps (use wall if needed).',
    ),
    (
      id: 'seed_squat_ten',
      category: 'Movement',
      phrase: 'Legs work; craving waits.',
      action: '10 easy bodyweight squats or sit-to-stands from a chair.',
    ),
    (
      id: 'seed_ankle_circles',
      category: 'Movement',
      phrase: 'Tiny joints, full attention.',
      action: 'Ankle circles 8 each direction, each foot.',
    ),
    (
      id: 'seed_reach_sky_toes',
      category: 'Movement',
      phrase: 'Lengthen, then fold gently.',
      action: 'Reach up, then soft hinge and hang for one breath (knees soft).',
    ),
    (
      id: 'seed_chest_opener',
      category: 'Movement',
      phrase: 'Undo the forward hunch.',
      action: 'Clasp hands behind back or open arms wide; open chest for 15s.',
    ),
    (
      id: 'seed_shake_out',
      category: 'Movement',
      phrase: 'Shake off residual charge.',
      action: 'Shake hands and arms 10 seconds, then bounce knees lightly.',
    ),
    (
      id: 'seed_stairs_or_hall',
      category: 'Movement',
      phrase: 'A short path is enough.',
      action: 'Walk a hallway length or up/down a few steps if available.',
    ),
    (
      id: 'seed_posture_reset',
      category: 'Movement',
      phrase: 'Stack the skeleton.',
      action: 'Feet under hips, lengthen spine, soften knees, 3 breaths tall.',
    ),
    (
      id: 'seed_wrist_flex',
      category: 'Movement',
      phrase: 'Thumbs rest; wrists recover.',
      action: 'Wrist circles and gentle finger stretches for ~20 seconds.',
    ),

    // ════════ Reframe / cognitive (~20) ════════
    (
      id: 'seed_personalized_statement',
      category: 'Reframe',
      phrase: 'I choose presence over the scroll right now.',
      action: 'Read this once slowly, then once with your name in mind.',
    ),
    (
      id: 'seed_small_aligned_action',
      category: 'Reframe',
      phrase: 'Urges pass; values point to the next step.',
      action:
          'Name one small action aligned with family, health, work, or education.',
    ),
    (
      id: 'seed_label_urge',
      category: 'Reframe',
      phrase:
          'I notice an urge to check my phone arising. It is a temporary private event.',
      action: 'Say the label neutrally (aloud or silently), then one slow breath.',
    ),
    (
      id: 'seed_three_went_well',
      category: 'Reframe',
      phrase: 'Attention goes where I place it.',
      action: 'Mentally list three things that went well today.',
    ),
    (
      id: 'seed_wave_not_emergency',
      category: 'Reframe',
      phrase: 'This urge is a wave. Checking is optional.',
      action: 'Watch the urge for two breaths without acting on it.',
    ),
    (
      id: 'seed_urge_surfing',
      category: 'Reframe',
      phrase: 'Surfing beats fighting.',
      action: 'Rate urge 0–10, breathe once, rate again — no need to make it zero.',
    ),
    (
      id: 'seed_defusion_thanks_mind',
      category: 'Reframe',
      phrase: 'Thanks, mind — noted.',
      action: 'Silently say “Thanks, mind” to the checking thought; let it pass.',
    ),
    (
      id: 'seed_not_urgent',
      category: 'Reframe',
      phrase: 'If it mattered, it can wait two minutes.',
      action: 'Ask: is this urgent in the next 2 minutes? Answer yes/no once.',
    ),
    (
      id: 'seed_future_self',
      category: 'Reframe',
      phrase: 'Future me wants fewer empty checks.',
      action: 'Ask what Future You wants in one sentence; answer briefly.',
    ),
    (
      id: 'seed_values_word',
      category: 'Reframe',
      phrase: 'One value word is a compass.',
      action: 'Pick one value word (kind, focused, present…) and repeat it thrice.',
    ),
    (
      id: 'seed_cost_benefit_quick',
      category: 'Reframe',
      phrase: 'Name the trade before you spend attention.',
      action: 'Name 1 cost of checking now and 1 benefit of waiting 10 minutes.',
    ),
    (
      id: 'seed_thought_on_leaf',
      category: 'Reframe',
      phrase: 'Thoughts can float by.',
      action: 'Imagine the urge on a leaf in a stream; watch it drift for 15s.',
    ),
    (
      id: 'seed_identity_line',
      category: 'Reframe',
      phrase: 'I am someone who can pause.',
      action: 'Repeat: “I can pause.” Three times, slower each time.',
    ),
    (
      id: 'seed_curiosity',
      category: 'Reframe',
      phrase: 'Curiosity softens the grip.',
      action: 'Ask: what am I hoping the phone will fix? Answer in one phrase.',
    ),
    (
      id: 'seed_boredom_ok',
      category: 'Reframe',
      phrase: 'Boredom is information, not an emergency.',
      action: 'Allow boredom for three breaths without fixing it.',
    ),
    (
      id: 'seed_anxiety_label',
      category: 'Reframe',
      phrase: 'Anxiety wants certainty; practice uncertainty.',
      action: 'Label: “anxiety” or “FOMO” or “habit.” One word is enough.',
    ),
    (
      id: 'seed_delay_ten',
      category: 'Reframe',
      phrase: 'Delay is a skill.',
      action: 'Decide: I can recheck only after this sequence — commit once.',
    ),
    (
      id: 'seed_gratitude_one',
      category: 'Reframe',
      phrase: 'One gratitude interrupts scarcity scrolling.',
      action: 'Name one person, place, or tool you’re glad exists.',
    ),
    (
      id: 'seed_permission_rest',
      category: 'Reframe',
      phrase: 'Rest without the screen is still rest.',
      action: 'Give yourself permission to do nothing useful for 20 seconds.',
    ),
    (
      id: 'seed_rehearse_putdown',
      category: 'Reframe',
      phrase: 'Practice the put-down before the pick-up.',
      action: 'Mime putting the phone face-down and stepping one step away.',
    ),

    // ════════ Brief behavioral activation (~20) ════════
    (
      id: 'seed_drink_water',
      category: 'Action',
      phrase: 'Care for the body first.',
      action: 'Drink a glass of water (or several good sips).',
    ),
    (
      id: 'seed_one_sentence_notebook',
      category: 'Action',
      phrase: 'Write something real; leave the feed alone.',
      action: 'Write one sentence in a physical notebook or sticky note.',
    ),
    (
      id: 'seed_supportive_message',
      category: 'Action',
      phrase: 'Connection beats the empty scroll.',
      action:
          'Send one brief supportive text or voice note to your designated person — that action only.',
    ),
    (
      id: 'seed_tidy_three',
      category: 'Action',
      phrase: 'A small complete act closes the urge loop.',
      action: 'Tidy one small surface or put away three items.',
    ),
    (
      id: 'seed_fresh_air_30s',
      category: 'Action',
      phrase: 'Light and air reorient the system.',
      action: 'Step outside or to a window for ~30s of air or natural light.',
    ),
    (
      id: 'seed_make_tea_start',
      category: 'Action',
      phrase: 'Start a caring ritual, not a scroll.',
      action: 'Fill a kettle/cup or prep a simple drink — begin only, no phone.',
    ),
    (
      id: 'seed_wash_hands_mindful',
      category: 'Action',
      phrase: 'Warm water is a reset button.',
      action: 'Wash hands slowly; notice temperature and scent of soap.',
    ),
    (
      id: 'seed_open_mail_one',
      category: 'Action',
      phrase: 'One real-world task.',
      action: 'Open one piece of mail/paper or sort one small stack item.',
    ),
    (
      id: 'seed_plant_or_pet',
      category: 'Action',
      phrase: 'Care outward, not into the glass.',
      action: 'Water a plant, pet an animal, or wipe one leaf/bowl if nearby.',
    ),
    (
      id: 'seed_shoes_on',
      category: 'Action',
      phrase: 'Prepare to move through the world.',
      action: 'Put on shoes or socks as if leaving — even if you stay.',
    ),
    (
      id: 'seed_calendar_glance_paper',
      category: 'Action',
      phrase: 'Plan offline for 20 seconds.',
      action: 'Glance at a paper calendar/list; note the next real task in words.',
    ),
    (
      id: 'seed_stretch_doorway',
      category: 'Action',
      phrase: 'Doorway as a threshold ritual.',
      action: 'Stand in a doorway; hand on frame; one slow breath each side.',
    ),
    (
      id: 'seed_smile_practice',
      category: 'Action',
      phrase: 'Face muscles feed state.',
      action: 'Soft half-smile for 10 seconds while exhaling slowly.',
    ),
    (
      id: 'seed_hydrate_and_stand',
      category: 'Action',
      phrase: 'Two tiny healthy acts.',
      action: 'Stand up and take three sips of water.',
    ),
    (
      id: 'seed_one_dish',
      category: 'Action',
      phrase: 'One dish is a win.',
      action: 'Wash or put away one dish/cup if available; else wipe one spot.',
    ),
    (
      id: 'seed_read_one_page',
      category: 'Action',
      phrase: 'Words on paper, not a feed.',
      action: 'Read one page or one paragraph of a physical book/article.',
    ),
    (
      id: 'seed_pray_or_meditate_short',
      category: 'Action',
      phrase: 'Orient to what matters most.',
      action: '20 seconds of quiet prayer, meditation, or sincere intention.',
    ),
    (
      id: 'seed_pack_one_item',
      category: 'Action',
      phrase: 'Future logistics beat present scrolling.',
      action: 'Pack or set out one item you need later today.',
    ),
    (
      id: 'seed_sunlight_eyes',
      category: 'Action',
      phrase: 'Daylight is medicine for rhythm.',
      action: 'Face outdoor light (or brightest indoor light) for ~20 seconds.',
    ),
    (
      id: 'seed_habit_stack_next',
      category: 'Action',
      phrase: 'Chain a good next step.',
      action: 'Do the next 20-second piece of an existing good habit (floss one tooth, open journal…).',
    ),
  ];

  assert(
    items.length <= 100,
    'Base built-in library should stay at most 100 items (have ${items.length}).',
  );

  final base = [
    for (var i = 0; i < items.length; i++)
      CompetingResponse(
        id: items[i].id,
        phrase: items[i].phrase,
        actionPrompt: items[i].action,
        category: items[i].category,
        enabled: true,
        sortOrder: i,
        weight: 1,
        requiresBonusUnlock: false,
      ),
  ];

  return [
    ...base,
    ...bonusCompetingResponses(startSortOrder: base.length),
  ];
}

/// Human-readable tip shown in Settings / editor.
const competingResponseDesignTip =
    'Keep each thought and action short — about 15–30 seconds to finish. '
    'Match the sequence timer to the prompt so you can complete it without rushing. '
    'The full library loads from this device (fast); each Rip-Cord pull picks one at random. '
    'Add your own anytime; disable any you do not want in the rotation.';
