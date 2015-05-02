// game start
//   cards loaded into library
//     opponents
//     yours
// turn
//   move_card from: library to: hand
//   move_card from: hand to: play
//     opponents
//     yours
// match
//   compare

var game_env_data_to_be_parsed = [];
var game_env_data = {};
var your_deck = [];

var Game = function() {
  this.oppo_library = [];
  this.your_library = [];
  this.oppo_hand = [];
  this.your_hand = [];
  this.oppo_play = [];
  this.your_play = [];
  this.current_turn = Game.OPPO_TURN;
  this.game_status = Game.IN_PLAY;
}

Game.LIBRARY_SIZE = 2;

Game.OPPO_TURN = 0;
Game.YOUR_TURN = 1;

Game.IN_PLAY = 0;
Game.ENDED = 1;

Game.prototype.load_external_files = function(env_url, deck_url) {
  [env_url, deck_url].forEach(function(url){
    $.ajax({
      async: false,
      url: url,
      dataType: 'json',
      success: function(data){
        game_env_data_to_be_parsed.push(data);
      },
      error: function(xhr, status, err) {
        console.error(url, status, err.toString());
      }
    });
  });
  game_env_data = game_env_data_to_be_parsed[0];
  your_deck = game_env_data_to_be_parsed[1];
}

Game.prototype.parse_unit = function() {
  // TODO parse different unit for parameters,
  // only leaving universal val for this game.
}

Game.prototype.get_criteria = function() {
  return game_env_data.winning_criteria;
}

Game.prototype.parse_criteria = function() {
  var param_name =  game_env_data.winning_criteria.param_name
  if (game_env_data.winning_criteria.comparator === 'gt') {
    return function(cards) {
      return cards.reduce(function(acc, card, i, arr){
        if (typeof card.parameters[param_name] !== 'undefined') {
          acc += parseInt(card.parameters[param_name].val);
        }
        return acc;
      },0);
    }
  } else {
    throw new Error('Invalid Criteria');
  }
}

Game.prototype.move_cards = function(from_arr, to_arr, to_size) {
  while(to_arr.length < to_size) {
    var shifted = from_arr.shift();
    to_arr.push(shifted);
  }
}

Game.prototype.load_cards_to_library = function() {
  // TODO read data
  this.move_cards(shuffle(game_env_data.cards), this.oppo_library, Game.LIBRARY_SIZE);
  this.move_cards(shuffle(your_deck), this.your_library, Game.LIBRARY_SIZE);
}

Game.prototype.draw_card = function() {
  var drawing_n = 1;
  if (this.current_turn === Game.OPPO_TURN) {
    this.move_cards(this.oppo_library, this.oppo_hand, (this.oppo_hand.length + drawing_n));
  } else {
    this.move_cards(this.your_library, this.your_hand, (this.your_hand.length + drawing_n));
  }
}

Game.prototype.play_card = function(i) {
  var move_chosen_card_on_top = function(cards) {
    var chosen_card_arr = cards.splice(i,1);
    cards.unshift(chosen_card_arr[0]);
  }
  if (this.current_turn === Game.OPPO_TURN) {
    move_chosen_card_on_top(this.oppo_hand);
    this.move_cards(this.oppo_hand, this.oppo_play, (this.oppo_play.length + 1));
    this.current_turn = Game.YOUR_TURN;
  } else {
    move_chosen_card_on_top(this.your_hand);
    this.move_cards(this.your_hand, this.your_play, (this.your_play.length + 1));
    this.current_turn = Game.OPPO_TURN;
  }
}

Game.prototype.match = function() {
  var score_calculator = this.parse_criteria();
  var oppo_score = score_calculator(this.oppo_play);
  var your_score = score_calculator(this.your_play);
  this.game_status = Game.ENDED;
  if (oppo_score > your_score) {
    return -1;
  } else if (your_score > oppo_score) {
    return 1;
  } else {
    return 0;
  }
}
