module LevelCapsEX
  def self.refresh_item_screen(screen)
    if screen.respond_to?(:pbHardRefresh)
      screen.pbHardRefresh
    elsif screen.respond_to?(:full_refresh)
      screen.full_refresh
    elsif screen.respond_to?(:refresh)
      screen.refresh
    end
  end
end


ItemHandlers::UseOnPokemonMaximum.add(:RARECANDY, proc { |item, pkmn|

  if LevelCapsEX.items_capped?
    max_lv = LevelCapsEX.level_cap

    next 0 if pkmn.level >= max_lv
    next max_lv - pkmn.level
  else

    max_lv = GameData::GrowthRate.max_level
    next max_lv - pkmn.level
  end
})

ItemHandlers::UseOnPokemon.add(:RARECANDY, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  elsif pkmn.level >= GameData::GrowthRate.max_level
    new_species = pkmn.check_evolution_on_level_up
    if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
      scene.pbDisplay(_INTL("It won't have any effect."))
      next false
    end

    pbFadeOutInWithMusic do
      evo = PokemonEvolutionScene.new
      evo.pbStartScreen(pkmn, new_species)
      evo.pbEvolution
      evo.pbEndScreen
      scene.pbRefresh if scene.respond_to?(:pbRefresh)
    end
    next true
  elsif LevelCapsEX.items_capped? && pkmn.level >= LevelCapsEX.level_cap

    new_species = Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL ? pkmn.check_evolution_on_level_up : nil
    if !new_species
      scene.pbDisplay(_INTL("{1} refuses to eat the {2}.", pkmn.name, GameData::Item.get(item).name))
      next false
    end
    pbFadeOutInWithMusic do
      evo = PokemonEvolutionScene.new
      evo.pbStartScreen(pkmn, new_species)
      evo.pbEvolution
      evo.pbEndScreen
      scene.pbRefresh if scene.respond_to?(:pbRefresh)
    end
    next true
  end

  pbSEPlay("Pkmn level up")
  target_level = pkmn.level + qty
  actual_levels_gained = 0

  qty.times do |i|
    break if pkmn.level >= target_level

    break if LevelCapsEX.items_capped? && pkmn.level >= LevelCapsEX.level_cap

    old_level = pkmn.level

    pkmn.level = pkmn.level + 1
    pkmn.calc_stats

    actual_levels_gained += 1 if pkmn.level > old_level

    moveList = pkmn.getMoveList
    moveList.each do |m|
      next if m[0] != pkmn.level
      pbLearnMove(pkmn, m[1]) { scene.pbUpdate if scene.respond_to?(:pbUpdate) }
    end

    new_species = pkmn.check_evolution_on_level_up
    if new_species
      pbFadeOutInWithMusic do
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(pkmn, new_species)
        evo.pbEvolution
        evo.pbEndScreen
        scene.pbRefresh if scene.respond_to?(:pbRefresh)
      end
    end
  end

  if actual_levels_gained > 0 && scene.respond_to?(:pbDisplay)
    if qty > 1
      scene.pbDisplay(_INTL("{1} gained {2} level(s) from {3} Rare Candies!", pkmn.name, actual_levels_gained, qty))
    else
      scene.pbDisplay(_INTL("{1} grew to Lv. {2}!", pkmn.name, pkmn.level))
    end
  end

  LevelCapsEX.refresh_item_screen(scene)
  next true
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYXS, proc { |item, pkmn|
  gain_amount = 100
  max_exp = LevelCapsEX.items_capped? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next [((max_exp - pkmn.exp) / gain_amount.to_f).ceil, 0].max
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXS, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 100, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYS, proc { |item, pkmn|
  gain_amount = 800
  max_exp = LevelCapsEX.items_capped? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next [((max_exp - pkmn.exp) / gain_amount.to_f).ceil, 0].max
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYS, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 800, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYM, proc { |item, pkmn|
  gain_amount = 3_000
  max_exp = LevelCapsEX.items_capped? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next [((max_exp - pkmn.exp) / gain_amount.to_f).ceil, 0].max
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYM, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 3_000, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYL, proc { |item, pkmn|
  gain_amount = 10_000
  max_exp = LevelCapsEX.items_capped? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next [((max_exp - pkmn.exp) / gain_amount.to_f).ceil, 0].max
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYL, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 10_000, qty, scene, item)
})

ItemHandlers::UseOnPokemonMaximum.add(:EXPCANDYXL, proc { |item, pkmn|
  gain_amount = 30_000
  max_exp = LevelCapsEX.items_capped? ? pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap) : pkmn.growth_rate.maximum_exp
  next [((max_exp - pkmn.exp) / gain_amount.to_f).ceil, 0].max
})

ItemHandlers::UseOnPokemon.add(:EXPCANDYXL, proc { |item, qty, pkmn, scene|
  next pbGainExpFromExpCandy(pkmn, 30_000, qty, scene, item)
})

def pbGainExpFromExpCandy(pkmn, base_amt, qty, scene, item)
  if pkmn.level >= GameData::GrowthRate.max_level || pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false
  end

  if LevelCapsEX.hard_cap? && pkmn.level >= LevelCapsEX.level_cap
    scene.pbDisplay(_INTL("{1} refuses to eat the {2}.", pkmn.name, GameData::Item.get(item).name))
    return false
  end

  if LevelCapsEX.items_capped?
    max_exp = pkmn.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap)
  else
    max_exp = pkmn.growth_rate.maximum_exp
  end
  exp_gain = base_amt * qty
  new_exp = pkmn.exp + exp_gain

  if new_exp > max_exp
    exp_gain = max_exp - pkmn.exp
    if exp_gain <= 0
      scene.pbDisplay(_INTL("{1} refuses to eat the {2}.", pkmn.name, GameData::Item.get(item).name))
      return false
    end
  end

  pbSEPlay("Pkmn level up")
  scene.pbSetHelpText("") if scene.respond_to?(:pbSetHelpText)
  if qty > 1
    (qty - 1).times { pkmn.changeHappiness("vitamin") }
  end
  pbChangeExp(pkmn, pkmn.exp + exp_gain, scene)
  LevelCapsEX.refresh_item_screen(scene)
  return true
end

class Game_Variables
  alias __level_caps__set_variable []= unless method_defined?(:__level_caps__set_variable)
  def []=(variable_id, value)
    old_value = self[variable_id]
    ret = __level_caps__set_variable(variable_id, value)

    if value != old_value

      if $DEBUG && LevelCapsEX::LOG_LEVEL_CAP_CHANGES
        if variable_id == LevelCapsEX::LEVEL_CAP_VARIABLE
          echoln "Current Level Cap updated from Lv. #{old_value} to Lv. #{value}"
        elsif variable_id == LevelCapsEX::LEVEL_CAP_MODE_VARIABLE
          mode_names = [
            "None",
            "Hard Cap",
            "EXP Cap",
            "Obedience Cap"
          ]
          old_name = mode_names[old_value] || "None"
          new_name = mode_names[value] || "None"
          echoln "Current Level Cap Mode updated from \"#{old_name}\" to \"#{new_name}\""
        end
      end

      if variable_id == LevelCapsEX::LEVEL_CAP_VARIABLE && value > 0 && old_value > 0
        LevelCapsEX.notify_cap_change(old_value, value)
        LevelCapsEX.award_stored_exp if value > old_value && LevelCapsEX::EXP_STORAGE_ENABLED
      end
    end
    return ret
  end
end

module Game
  class << self
    alias __level_caps__start_new start_new unless method_defined?(:__level_caps__start_new)
  end

  def self.start_new(*args)
    __level_caps__start_new(*args)
    $game_variables[LevelCapsEX::LEVEL_CAP_MODE_VARIABLE] = LevelCapsEX::DEFAULT_LEVEL_CAP_MODE

    if defined?(LevelCapsEX::BADGE_AUTO_CAP) && LevelCapsEX::BADGE_AUTO_CAP
      starting_cap = LevelCapsEX::BADGE_LEVEL_CAPS[0]
      $game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE] = starting_cap if starting_cap
    end
  end
end

module LevelCapsEX
  module_function

  def level_cap
    return $game_variables[LEVEL_CAP_VARIABLE] if $game_variables && $game_variables[LEVEL_CAP_VARIABLE] > 0
    return Settings::MAXIMUM_LEVEL
  end

  def level_cap_mode
    return 0 unless $game_variables
    lv_cap_mode = $game_variables[LEVEL_CAP_MODE_VARIABLE]
    return lv_cap_mode if [1, 2, 3].include?(lv_cap_mode)
    return 0
  end

  def hard_cap?
    result = level_cap_mode == 1 && $game_variables && $game_variables[LEVEL_CAP_VARIABLE] > 0
    return result
  end

  def soft_cap?
    return $game_variables && level_cap_mode == 2 && $game_variables[LEVEL_CAP_VARIABLE] > 0
  end

  def obedience_cap?
    return $game_variables && level_cap_mode == 3 && $game_variables[LEVEL_CAP_VARIABLE] > 0
  end

  def items_capped?
    return true if hard_cap?
    return soft_cap? && ITEMS_RESPECT_SOFT_CAP
  end

  def hard_level_cap
    max_lv = Settings::MAXIMUM_LEVEL
    return max_lv if !$game_variables
    lv_cap_mode = $game_variables[LEVEL_CAP_MODE_VARIABLE]
    lv_cap = $game_variables[LEVEL_CAP_VARIABLE]
    return max_lv if lv_cap > max_lv
    return lv_cap if lv_cap > 0 && lv_cap_mode == 1
    return max_lv
  end

  def can_gain_exp?(pokemon)
    return false if hard_cap? && pokemon.level >= level_cap
    return true
  end

  def current_level_cap
    cap_value = $game_variables ? $game_variables[LEVEL_CAP_VARIABLE] : nil
    return cap_value if cap_value && cap_value > 0
    return Settings::MAXIMUM_LEVEL
  end

  def voltseons_pause_menu_exists?
    return defined?(VoltseonsPauseMenu_Scene)
  end
end

if LevelCapsEX.voltseons_pause_menu_exists?
  class VPM_LevelCapHud < Component
    def start_component(viewport, menu)
      super(viewport, menu)
      @sprites["overlay"] = BitmapSprite.new(Graphics.width / 2, 32, viewport)
      @sprites["overlay"].ox = @sprites["overlay"].bitmap.width
      @sprites["overlay"].x = Graphics.width
      @sprites["overlay"].y = 90
      @base_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTCOLOR, Color.new(248, 248, 248))
      @shdw_color = $PokemonSystem.from_current_menu_theme(MENU_TEXTOUTLINE, Color.new(48, 48, 48))
    end

    def should_draw?; return true; end

    def refresh
      level_cap = LevelCapsEX.current_level_cap
      text = _INTL("Current Lvl Cap: {1}", level_cap)
      @sprites["overlay"].bitmap.clear
      pbSetSystemFont(@sprites["overlay"].bitmap)
      pbDrawTextPositions(@sprites["overlay"].bitmap, [
        [text, (Graphics.width / 2) - 8, 12, 1, @base_color, @shdw_color]
      ])
    end
  end

  MENU_COMPONENTS << :VPM_LevelCapHud if defined?(MENU_COMPONENTS)
end

if LevelCapsEX::BADGE_AUTO_CAP
  module LevelCapsEX
    module_function

    @last_badge_count = -1

    def update_cap_for_badges
      return if !$game_variables || !$player
      badge_count = $player.badge_count

      last = $PokemonGlobal ? ($PokemonGlobal.level_cap_last_badge_count || -1) : @last_badge_count
      return if badge_count == last
      if $PokemonGlobal
        $PokemonGlobal.level_cap_last_badge_count = badge_count
      else
        @last_badge_count = badge_count
      end
      cap = BADGE_LEVEL_CAPS[badge_count]
      return if !cap
      current = $game_variables[LEVEL_CAP_VARIABLE]
      if cap > current
        $game_variables[LEVEL_CAP_VARIABLE] = cap
      end
    end
  end

  EventHandlers.add(:on_enter_map, :level_cap_badge_check,
    proc { |_old_map_id|
      LevelCapsEX.update_cap_for_badges if LevelCapsEX::BADGE_AUTO_CAP
    }
  )

  EventHandlers.add(:on_end_battle, :level_cap_badge_check_battle,
    proc { |_decision, _can_lose|
      LevelCapsEX.update_cap_for_badges if LevelCapsEX::BADGE_AUTO_CAP
    }
  )
end

class PokemonGlobalMetadata
  attr_writer :level_cap_stored_exp
  attr_accessor :level_cap_pending_evolutions

  attr_accessor :level_cap_last_badge_count

  def level_cap_stored_exp
    @level_cap_stored_exp = {} if !@level_cap_stored_exp.is_a?(Hash)
    return @level_cap_stored_exp
  end
end

module LevelCapsEX
  module_function

  def stored_exp
    return $PokemonGlobal.level_cap_stored_exp if $PokemonGlobal

    @stored_exp ||= {}
    return @stored_exp
  end

  def pending_evolutions
    return [] if !$PokemonGlobal
    $PokemonGlobal.level_cap_pending_evolutions ||= []
  end

  def evolve_from_stored_exp(pkmn)
    new_species = pkmn.check_evolution_on_level_up
    return if !new_species
    pbFadeOutInWithMusic do
      evo = PokemonEvolutionScene.new
      evo.pbStartScreen(pkmn, new_species)
      evo.pbEvolution
      evo.pbEndScreen
    end
  end

  def process_pending_evolutions
    return if @processing_pending_evolutions || pending_evolutions.empty? || !$scene.is_a?(Scene_Map)
    return if $game_temp.in_battle || $game_temp.in_menu || $game_temp.message_window_showing
    return if pbMapInterpreterRunning?
    @processing_pending_evolutions = true
    begin
      until pending_evolutions.empty?
        pid = pending_evolutions.shift
        pkmn = $player.party.find { |member| member && member.personalID == pid }
        evolve_from_stored_exp(pkmn) if pkmn
      end
    ensure
      @processing_pending_evolutions = false
    end
  end

  def store_blocked_exp(pkmn, idx_party, defeated_battler, num_partic, exp_share, exp_all, trainer_battle = false)
    return if !EXP_STORAGE_ENABLED
    level = defeated_battler.level
    a = level * defeated_battler.pokemon.base_exp
    pid = pkmn.personalID
    is_partic = defeated_battler.participants.include?(idx_party)
    has_share = exp_share.include?(idx_party)

    exp = 0
    if has_share && is_partic
      exp = a / (2 * [num_partic, 1].max) + a / (2 * [exp_share.length, 1].max)
    elsif has_share
      exp = a / [exp_share.length, 1].max
    elsif is_partic
      exp = a / [num_partic, 1].max
    elsif exp_all
      exp = a / 2
    else
      return
    end
    return if exp <= 0

    exp = (exp * 1.5).floor if Settings::MORE_EXP_FROM_TRAINER_POKEMON && trainer_battle

    if Settings::SCALED_EXP_FORMULA
      exp /= 5
      level_adjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
      level_adjust **= 5
      level_adjust = Math.sqrt(level_adjust)
      exp = (exp * level_adjust).floor
      exp += 1 if is_partic || has_share
    else
      exp /= 7
    end

    if $player
      is_outsider = (pkmn.owner.id != $player.id ||
                     (pkmn.owner.language != 0 && pkmn.owner.language != $player.language))
      if is_outsider
        if pkmn.owner.language != 0 && pkmn.owner.language != $player.language
          exp = (exp * 1.7).floor
        else
          exp = (exp * 1.5).floor
        end
      end
    end

    exp = exp * 3 / 2 if $bag&.has?(:EXPCHARM)
    exp = [exp, 1].max
    stored_exp[pid] ||= 0
    stored_exp[pid] += exp
  end

  def apply_stored_exp(pkmn, verbose)
    return if !pkmn || pkmn.egg?
    pid = pkmn.personalID
    banked = stored_exp[pid]
    return if !banked || banked <= 0

    max_exp = pkmn.growth_rate.minimum_exp_for_level(level_cap)
    award = [banked, [max_exp - pkmn.exp, 0].max].min
    if award > 0
      old_level = pkmn.level
      pkmn.exp += award
      pkmn.calc_stats
      new_level = pkmn.level
      if new_level > old_level
        pbMessage(_INTL("{1} grew to Lv. {2} from stored Exp!", pkmn.name, new_level)) if verbose

        move_list = pkmn.getMoveList
        (old_level + 1..new_level).each do |lv|
          move_list.each do |move_level, move_id|
            next if move_level != lv
            verbose ? pbLearnMove(pkmn, move_id) : pkmn.learn_move(move_id)
          end
        end
        if verbose && pkmn.check_evolution_on_level_up
          if $scene.is_a?(Scene_Map) && !$game_temp.in_battle
            evolve_from_stored_exp(pkmn)
          elsif !pending_evolutions.include?(pid)
            pending_evolutions << pid
          end
        end
      end
    end
    remaining = banked - award
    if remaining > 0
      stored_exp[pid] = remaining
    else
      stored_exp.delete(pid)
    end
  end

  def award_stored_exp
    return if !$player || stored_exp.empty?
    owned_ids = {}
    $player.party.each do |pkmn|
      next if !pkmn
      owned_ids[pkmn.personalID] = true
      apply_stored_exp(pkmn, true)
    end
    if $PokemonGlobal&.day_care
      $PokemonGlobal.day_care.slots.each do |slot|
        pkmn = slot.pokemon
        next if !pkmn
        owned_ids[pkmn.personalID] = true
        apply_stored_exp(pkmn, false)
      end
    end
    if $PokemonStorage
      (0...$PokemonStorage.maxBoxes).each do |b|
        (0...$PokemonStorage.maxPokemon(b)).each do |i|
          pkmn = $PokemonStorage[b, i]
          next if !pkmn
          owned_ids[pkmn.personalID] = true
          apply_stored_exp(pkmn, false)
        end
      end
      stored_exp.delete_if { |pid, _| !owned_ids[pid] }
    end
  end
end

class DayCare::DayCareSlot
  alias level_caps_add_exp add_exp unless method_defined?(:level_caps_add_exp)

  def add_exp(amount = 1)
    return level_caps_add_exp(amount) unless filled? && LevelCapsEX.hard_cap?
    cap_exp = @pokemon.growth_rate.minimum_exp_for_level(LevelCapsEX.level_cap)
    gained = [amount, [cap_exp - @pokemon.exp, 0].max].min
    if LevelCapsEX::EXP_STORAGE_ENABLED && amount > gained
      LevelCapsEX.stored_exp[@pokemon.personalID] ||= 0
      LevelCapsEX.stored_exp[@pokemon.personalID] += amount - gained
    end
    level_caps_add_exp(gained) if gained > 0
  end
end

EventHandlers.add(:on_frame_update, :level_cap_pending_evolutions, proc {
  LevelCapsEX.process_pending_evolutions
})

module LevelCapsEX
  module_function

  def notify_cap_change(old_value, new_value)
    return if old_value == new_value
    return if !$scene || !$scene.is_a?(Scene_Map)
    if new_value > old_value
      pbMessage(_INTL("\\se[Pkmn level up]Level Cap increased to Lv. {1}!", new_value))
    elsif new_value < old_value
      pbMessage(_INTL("Level Cap decreased to Lv. {1}.", new_value))
    end
  end
end

if defined?(PokemonPartyPanel) && PokemonPartyPanel.method_defined?(:draw_level)
class PokemonPartyPanel < Sprite
  LEVEL_CAP_COLOR        = Color.new(255, 165, 0)
  LEVEL_CAP_SHADOW       = Color.new(160, 80, 0)
  LEVEL_OVER_CAP_COLOR   = Color.new(255, 50, 50)
  LEVEL_OVER_CAP_SHADOW  = Color.new(160, 20, 20)

  alias __level_cap_draw_level draw_level unless method_defined?(:__level_cap_draw_level)

  def draw_level
    return if @pokemon.egg?

    pbDrawImagePositions(@overlaysprite.bitmap,
                         [[_INTL("Graphics/UI/Party/overlay_lv"), 20, 70, 0, 0, 22, 14]])

    base_color   = TEXT_BASE_COLOR
    shadow_color = TEXT_SHADOW_COLOR
    if defined?(LevelCapsEX) && (LevelCapsEX.hard_cap? || LevelCapsEX.soft_cap? || LevelCapsEX.obedience_cap?)
      cap = LevelCapsEX.level_cap
      if @pokemon.level > cap
        base_color   = LEVEL_OVER_CAP_COLOR
        shadow_color = LEVEL_OVER_CAP_SHADOW
      elsif @pokemon.level == cap
        base_color   = LEVEL_CAP_COLOR
        shadow_color = LEVEL_CAP_SHADOW
      end
    end

    pbSetSmallFont(@overlaysprite.bitmap)
    pbDrawTextPositions(@overlaysprite.bitmap,
                        [[@pokemon.level.to_s, 42, 68, :left, base_color, shadow_color]])
    pbSetSystemFont(@overlaysprite.bitmap)
  end
end
end

if defined?(PokemonSummary_Scene) && PokemonSummary_Scene.method_defined?(:drawPageOne)
class PokemonSummary_Scene
  alias __level_cap_draw_page_one drawPageOne unless method_defined?(:__level_cap_draw_page_one)

  def drawPageOne
    __level_cap_draw_page_one
    return if @pokemon.egg? || @pokemon.shadowPokemon?
    return unless LevelCapsEX.hard_cap? || LevelCapsEX.soft_cap? || LevelCapsEX.obedience_cap?
    cap = LevelCapsEX.level_cap
    return if @pokemon.level < cap

    over_cap = @pokemon.level > cap
    label = over_cap ? _INTL("Over Level Cap!") : _INTL("At Level Cap")
    base = over_cap ? Color.new(248, 56, 32) : Color.new(200, 120, 24)
    shadow = over_cap ? Color.new(224, 152, 144) : Color.new(240, 200, 136)
    textpos = [[label, 488, 246, :right, base, shadow]]
    if LevelCapsEX::EXP_STORAGE_ENABLED
      banked = LevelCapsEX.stored_exp[@pokemon.personalID] || 0
      textpos << [_INTL("Stored: {1}", banked.to_s_formatted), 488, 310, :right, base, shadow] if banked > 0
    end
    pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
  end
end
end

if defined?(UI::PokemonSummaryVisuals)
class UI::PokemonSummaryVisuals
  alias __level_cap_draw_exp draw_exp unless method_defined?(:__level_cap_draw_exp)

  def draw_exp
    __level_cap_draw_exp
    return if @pokemon.egg?
    return if !(LevelCapsEX.hard_cap? || LevelCapsEX.soft_cap? || LevelCapsEX.obedience_cap?)
    cap = LevelCapsEX.level_cap
    return if @pokemon.level < cap
    if @pokemon.level > cap
      label  = _INTL("Over Level Cap!")
    else
      label  = _INTL("At Level Cap")
    end
    banked = 0
    if LevelCapsEX::EXP_STORAGE_ENABLED
      banked = LevelCapsEX.stored_exp[@pokemon.personalID] || 0
    end
    label = _INTL("{1} · Stored Exp: {2}", label, banked.to_s_formatted) if banked > 0
    draw_text(label, 490, 278, align: :right, theme: :black)
  end
end
end

if $DEBUG
  MenuHandlers.add(:debug_menu, :level_cap_menu, {
    "name"        => _INTL("Level Cap options..."),
    "parent"      => :field_menu,
    "description" => _INTL("Set level cap, cap mode, view stored EXP, and other Level Caps Ex options.")
  })

  MenuHandlers.add(:debug_menu, :level_cap_set_cap, {
    "name"        => _INTL("Set Level Cap"),
    "parent"      => :level_cap_menu,
    "description" => _INTL("Change the current level cap value."),
    "effect"      => proc {
      current = $game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE]
      params = ChooseNumberParams.new
      params.setRange(1, Settings::MAXIMUM_LEVEL)
      params.setDefaultValue(current)
      new_cap = pbMessageChooseNumber(_INTL("Set the level cap (current: {1}).", current), params)
      if new_cap != current
        $game_variables[LevelCapsEX::LEVEL_CAP_VARIABLE] = new_cap
        pbMessage(_INTL("Level cap set to {1}.", new_cap))
      end
    }
  })

  MenuHandlers.add(:debug_menu, :level_cap_set_mode, {
    "name"        => _INTL("Set Level Cap Mode"),
    "parent"      => :level_cap_menu,
    "description" => _INTL("Change the level cap mode (Hard/Soft/Obedience/Off)."),
    "effect"      => proc {
      current = $game_variables[LevelCapsEX::LEVEL_CAP_MODE_VARIABLE]
      mode_names = ["Off (0)", "Hard Cap (1)", "Soft/EXP Cap (2)", "Obedience Cap (3)"]
      choice = pbMessage(_INTL("Current mode: {1}. Choose new mode:", mode_names[current] || "Off"),
                         mode_names, -1)
      if choice >= 0 && choice != current
        $game_variables[LevelCapsEX::LEVEL_CAP_MODE_VARIABLE] = choice
        pbMessage(_INTL("Level cap mode set to {1}.", mode_names[choice]))
      end
    }
  })

  MenuHandlers.add(:debug_menu, :level_cap_view_stored_exp, {
    "name"        => _INTL("View Stored EXP"),
    "parent"      => :level_cap_menu,
    "description" => _INTL("View the EXP piggy bank for each party Pokémon."),
    "effect"      => proc {
      if !LevelCapsEX::EXP_STORAGE_ENABLED
        pbMessage(_INTL("EXP Storage is disabled in config."))
        next
      end
      lines = []
      $player.party.each do |pkmn|
        next if !pkmn || pkmn.egg?
        banked = LevelCapsEX.stored_exp[pkmn.personalID] || 0
        lines.push(_INTL("{1} (Lv.{2}): {3} stored EXP", pkmn.name, pkmn.level, banked))
      end
      if lines.empty?
        pbMessage(_INTL("No Pokémon in party."))
      else
        pbMessage(lines.join("\n"))
      end
    }
  })

  MenuHandlers.add(:debug_menu, :level_cap_award_stored, {
    "name"        => _INTL("Award Stored EXP Now"),
    "parent"      => :level_cap_menu,
    "description" => _INTL("Immediately award all stored EXP to party Pokémon."),
    "effect"      => proc {
      if !LevelCapsEX::EXP_STORAGE_ENABLED
        pbMessage(_INTL("EXP Storage is disabled in config."))
        next
      end
      if LevelCapsEX.stored_exp.empty?
        pbMessage(_INTL("No stored EXP to award."))
        next
      end
      LevelCapsEX.award_stored_exp
      pbMessage(_INTL("Stored EXP has been awarded."))
    }
  })

  MenuHandlers.add(:debug_menu, :level_cap_clear_stored, {
    "name"        => _INTL("Clear All Stored EXP"),
    "parent"      => :level_cap_menu,
    "description" => _INTL("Delete all stored EXP data (cannot be undone)."),
    "effect"      => proc {
      if LevelCapsEX.stored_exp.empty?
        pbMessage(_INTL("No stored EXP to clear."))
        next
      end
      if pbConfirmMessage(_INTL("Clear ALL stored EXP? This cannot be undone."))
        LevelCapsEX.stored_exp.clear
        pbMessage(_INTL("All stored EXP cleared."))
      end
    }
  })

  MenuHandlers.add(:debug_menu, :level_cap_toggle_bypass, {
    "name"        => _INTL("Toggle Level Cap Bypass"),
    "parent"      => :level_cap_menu,
    "description" => _INTL("Toggle the bypass switch that disables level caps for enemies."),
    "effect"      => proc {
      sw = LevelCapsEX::LEVEL_CAP_BYPASS_SWITCH
      $game_switches[sw] = !$game_switches[sw]
      state = $game_switches[sw] ? "ON" : "OFF"
      pbMessage(_INTL("Level Cap Bypass Switch is now {1}.", state))
    }
  })
end
