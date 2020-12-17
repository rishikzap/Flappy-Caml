open Graphics
open Camlimages
open Images
open Game 
let open_screen = Graphics.open_graph " 600x700";

  (* right now, 0 maps to mushroom, 1 maps to slow powerup sprite <- for draw *)

type pipe_array = ((Graphics.image * (int)) * (Graphics.image * (int))) array

type t = {
  canvas_width : int; 
  canvas_height : int;
  player : Game.t; 
  camel_image : Graphics.image;
  camel_index : int; 
  camel_image_array: Graphics.image array;
  pipe_array : pipe_array; 
  cactus_image : Graphics.image;
  powerup_image : Graphics.image;
  ground_image: Graphics.image;
}

let array_of_image img =
  match img with
  | Images.Index8 bitmap ->
    let w = bitmap.Index8.width
    and h = bitmap.Index8.height
    and colormap = bitmap.Index8.colormap.map in
    let cmap = Array.map (fun {r = r; g = g; b = b} -> Graphics.rgb r g b) 
        colormap in
    if bitmap.Index8.transparent <> -1 then
      cmap.(bitmap.Index8.transparent) <- transp;
    Array.init h (fun i ->
        Array.init w (fun j -> cmap.(Index8.unsafe_get bitmap j i)))
  | Index16 bitmap ->
    let w = bitmap.Index16.width
    and h = bitmap.Index16.height
    and colormap = bitmap.Index16.colormap.map in
    let cmap = Array.map (fun {r = r; g = g; b = b} -> rgb r g b) colormap in
    if bitmap.Index16.transparent <> -1 then
      cmap.(bitmap.Index16.transparent) <- transp;
    Array.init h (fun i ->
        Array.init w (fun j -> cmap.(Index16.unsafe_get bitmap j i)))
  | Rgb24 bitmap ->
    let w = bitmap.Rgb24.width
    and h = bitmap.Rgb24.height in
    Array.init h (fun i ->
        Array.init w (fun j ->
            let {r = r; g = g; b = b} = Rgb24.unsafe_get bitmap j i in
            rgb r g b))
  | Rgba32 _ -> failwith "RGBA not supported"
  | Cmyk32 _ -> failwith "CMYK not supported"

(** [get_img] img takes the filename of the image as a ppm file and outputs
    a Graphics.image, which can be displayed with Graphics module. *)
let get_img img =
  Images.load img [] |> array_of_image |> make_image

let reg_top_pipe = get_img "assets/top.ppm"

let reg_bottom_pipe = get_img "assets/bottom.ppm"

let high_top_pipe = get_img "assets/top_high.ppm"

let high_bottom_pipe = get_img "assets/bottom_high.ppm"

let low_top_pipe = get_img "assets/top_low.ppm"

let low_bottom_pipe = get_img "assets/bottom_low.ppm"

let cactus = get_img "assets/cactus.pbm"

let clarkson = get_img "assets/clarkson.ppm"

let gries = get_img "assets/gries.ppm"

let w_white = get_img "assets/white.ppm"

let camel = get_img "assets/camel_1.pbm"

let death = get_img "assets/deathimage.pbm"

let mushroom = get_img "assets/mario_mushroom.pbm"

let bomb = get_img "assets/bomb.ppm"

let bomber = get_img "assets/bomber.ppm"

(* [make_player_array lst] constructs image array of player, used for
   animations *)
let make_player_array array = 
  Array.map get_img array 

(* GLOBAL VARIABLES *)
let clarkson_array = make_player_array 
    [| "assets/clarkson.ppm"; 
       "assets/clarkson1.ppm"; 
       "assets/clarkson2.ppm";
       "assets/clarkson3.ppm" |]
let gries_array = make_player_array [|"assets/gries.ppm"|]

let camel_array = make_player_array 
    [|"assets/camel_1.pbm"; 
      "assets/camel_2.pbm"; 
      "assets/camel_3.pbm"|]

let death_array = make_player_array [|"assets/deathimage.pbm"|]

let sprite_arrays = [|clarkson_array; gries_array; camel_array; death_array|]

let sprites = [|clarkson; gries; camel; death|]

let powerup_array = [|mushroom; death|] (* change sprites for diff powerups *)

let pipe_array = [|((reg_top_pipe, 500), (reg_bottom_pipe, 100)); 
                   ((high_top_pipe, 575), (high_bottom_pipe, 100)); 
                   ((low_top_pipe, 400), (low_bottom_pipe, 100))|]

let make_state player = {
  canvas_width = 600; 
  canvas_height = 700;
  player = player; 
  camel_image = camel; (* get rid of *)
  pipe_array = pipe_array;
  camel_image_array = camel_array; 
  camel_index = 0;
  cactus_image = cactus; 
  powerup_image = mushroom;
  ground_image = get_img "assets/new_ground.ppm";
}

let set_sprite t image_array_no = 
  {t with 
   camel_image_array = sprite_arrays.(image_array_no - 1);
   camel_image =  sprites.(image_array_no - 1)}

let rec animate_player frame t =  
  if frame mod 5 = 0 then 
    (t.camel_index + 1) mod Array.length t.camel_image_array
  else t.camel_index

(* [update_fly y score index pipe pipe_type t] updates t appropriately when
   the state is fly (go) , if draw = -1, then powerup = None *)
let update_fly player frame t  =
  {t with player = player;
          camel_index = animate_player frame t}

let update_run player frame t =
  {t with 
   player = player; 
   camel_index = animate_player frame t}

let update_torun player frame t = 
  {t with 
   player = player;
   camel_index = animate_player frame t;
  }

let update_death player t = 
  {t with player = player}

let update_bomb player frame t =
  {t with 
   player = player; 
   camel_index = animate_player frame t;
  }

let draw_camel t =
  (* let light_blue = rgb 76 186 196 in
     set_color (light_blue);
     fill_rect t.camel.pre_x t.camel.pre_y 50 50;  *)
  let x = Game.get_player_x t.player in 
  let y = Game.get_player_y t.player in 
  draw_image (t.camel_image_array.(t.camel_index)) x y 


let draw_death_img t =
  let light_blue = rgb 76 186 196 in
  set_color (light_blue);
  let x = Game.get_player_x t.player in 
  let y = Game.get_player_y t.player in 
  draw_image death x y 

let draw_camel_torun t =
  draw_image (t.camel_image_array.(t.camel_index)) (Game.get_player_x t.player) 
    (Game.get_player_y t.player)

let draw_ground init = 
  draw_image init.ground_image 0 0;
  draw_image init.ground_image 190 0;
  draw_image init.ground_image 380 0;
  draw_image init.ground_image 570 0

let draw_back init = 
  let light_blue = rgb 76 186 196 in
  set_color (light_blue);
  fill_rect 0 0 init.canvas_width init.canvas_height

let draw_pipes init = 
  let pipe_type = Game.get_pipe_type init.player in 
  match init.pipe_array.(pipe_type) with 
  | ((top , y), (bottom, y')) -> 
    let x = Game.get_obs_x init.player in 
    draw_image bottom x y';
    draw_image top x y

let draw_cactus init = 
  draw_image cactus (Game.get_obs_x init.player) 100

let draw_score init =
  let score_string = string_of_int (Game.get_score init.player) in
  moveto 520 620;
  set_text_size 500;
  set_color black;
  (*set_font "-*-Helvetica-medium-r-normal--50-*-*-*-*-*-iso8859-1";*)
  draw_string score_string;
  set_color white

let draw_powerups init = 
  let index = Game.int_of_powerup init.player in 
  if index <> -1 then 
    let (x, y) = 
      if Game.get_pwr_active init.player then 
        0, 0 
      else 
        let x', y' = Game.get_pwr_pos init.player in 
        x', y' in 
    draw_image powerup_array.(index) x y 
  else 
    let lightblue = rgb 76 186 196 in
    set_color lightblue;
    fill_rect 35 35 0 0

let draw_bomber init = 
  draw_image bomber (Game.get_bomber_x init.player) 500 

let rec draw_bomb_ob_aux lst =  
  match lst with 
  | h::t ->
    begin 
      match h with 
      | None -> (); draw_bomb_ob_aux t 
      | Bomb (x, y, b) -> 
        begin 
          match b with 
          | true -> draw_image bomb x y; draw_bomb_ob_aux t 
          | false ->  draw_bomb_ob_aux t 
        end 
    end 
  | [] -> ()

let draw_bomb_ob init = 
  (* draw_erase_bombs init.bomb.past.bombs; *)
  draw_bomb_ob_aux (Game.get_bombs_list init.player)

let draw_fly init = 
  draw_back init; 
  draw_ground init;
  draw_pipes init;
  draw_camel init;
  draw_powerups init;
  draw_score init

let draw_run init = 
  draw_back init; 
  draw_ground init;
  draw_cactus init;
  draw_camel init; 
  draw_powerups init;
  draw_score init

let draw_bomb init = 
  draw_back init;
  draw_ground init;
  draw_camel init;
  draw_bomb_ob init;
  draw_bomber init;
  draw_score init

let draw_death init =
  draw_death_img init

(* let draw_pause =
   failwith "pause" *)
let draw_gameover_ascii init = 
  set_color black;
  moveto 80 500;
  draw_string " _______  _______  __   __  _______    _______  __   __  _______  ______   ";
  moveto 80 490;
  draw_string "|       ||   _   ||  |_|  ||       |  |       ||  | |  ||       ||    _ |  ";
  moveto 80 480;
  draw_string "|    ___||  |_|  ||       ||    ___|  |   _   ||  |_|  ||    ___||   | ||  ";
  moveto 80 470;
  draw_string "|   | __ |       ||       ||   |___   |  | |  ||       ||   |___ |   |_||_ ";
  moveto 80 460;
  draw_string "|   ||  ||       ||       ||    ___|  |  |_|  ||       ||    ___||    __  |";
  moveto 80 450;
  draw_string "|   |_| ||   _   || ||_|| ||   |___   |       | |     | |   |___ |   |  | |";
  moveto 80 440;
  draw_string "|_______||__| |__||_|   |_||_______|  |_______|  |___|  |_______||___|  |_|"

let draw_gameover init = 
  Graphics.clear_graph ();
  let light_blue = rgb 76 186 196 in
  set_color (light_blue);
  fill_rect 0 0 600 700;
  draw_image high_bottom_pipe 0 100;
  draw_image high_top_pipe 0 575;
  draw_image low_bottom_pipe 530 100;
  draw_image low_top_pipe 530 400;
  draw_ground init;
  draw_gameover_ascii init; 
  moveto 260 275;
  draw_string "High Score: ";
  draw_string (string_of_int (Game.get_highscore init.player)); 
  set_text_size 50;
  let score_s = string_of_int (Game.get_score init.player) in 
  moveto 275 325;
  set_font "-*-Helvetica-medium-r-normal--80-*-*-*-*-*-iso8859-1";
  draw_string score_s;
  set_font "fixed"

let draw_flappycaml x y = 
  moveto x y;
  draw_string "  _____ _                            ____                _ ";
  moveto x (y -10);
  draw_string " |  ___| | __ _ _ __  _ __  _   _   / ___|__ _ _ __ ___ | |";
  moveto x (y-20);
  draw_string " | |_  | |/ _` | '_ \| '_ \| | | | | |   / _` | '_ ` _ \| |";
  moveto x (y-30);
  draw_string " |  _| | | (_| | |_) | |_) | |_| | | |__| (_| | | | | | | |";
  moveto x (y-40);
  draw_string " |_|   |_|\__,_| .__/| .__/ \__, |  \____\__,_|_| |_| |_|_|";
  moveto x (y-50);
  draw_string "               |_|   |_|    |___/                          "

let draw_camel_ascii init x y =
  moveto x y;
  draw_string "                    ,,__                               ";
  moveto x (y-10);
  draw_string "          ..  ..   / o._)                   .---.      ";
  moveto x (y-20);
  draw_string "          /--'/--\  \-'||        .----.    .'     '.   ";
  moveto x (y-30);
  draw_string "         /        \_/ / |      .'      '..'         '-.";
  moveto x (y-40);
  draw_string "       .'\  \__\  __.'.'     .'          -._           ";
  moveto x (y-50);
  draw_string "         )\ |  )\ |      _.'                           ";
  moveto x (y-60);
  draw_string "        // \\ // \\                                    ";
  moveto x (y-70);
  draw_string "       ||_  \\|_  \\_                                  ";
  moveto x (y-80);
  draw_string "       '--' '--'' '--'                                 "  


(* Camel ascii art citation:   "------------------------------------------------
   Thank you for visiting https://asciiart.website/
   This ASCII pic can be found at
   https://asciiart.website/index.php?art=animals/camels " *)

let draw_start init =
  Graphics.clear_graph ();
  let light_blue = rgb 76 186 196 in
  set_color (light_blue);
  fill_rect 0 0 600 700;
  draw_image high_bottom_pipe 0 100;
  draw_image high_top_pipe 0 575;
  draw_image low_bottom_pipe 530 100;
  draw_image low_top_pipe 530 400;
  draw_ground init;
  set_color black;
  set_text_size 10;
  draw_flappycaml 120 500;
  draw_image init.camel_image 280 300;
  moveto 240 400;
  set_color red;
  draw_string "Press any key to start";
  fill_rect 255 195 100 25; (* rectangle box that can be clicked *)
  fill_rect 255 140 100 25; 
  moveto 270 202;
  set_color white;
  draw_string "Instructions";
  moveto 283 147;
  draw_string "Sprites"

let draw_instructions init = 
  Graphics.clear_graph ();
  let light_blue = rgb 76 186 196 in
  set_color (light_blue);
  fill_rect 0 0 600 700;
  set_color black; 
  draw_flappycaml 120 500;
  moveto 150 400;
  draw_string "Press spacebar to jump through the obstacles when flying";
  moveto 150 380;
  draw_string "and over the obstacles when running.";
  moveto 150 350;
  draw_string "Press 'q' to exit the game application.";
  draw_camel_ascii init 100 300;
  set_color red; 
  fill_rect 450 50 100 50;
  moveto 465 70;
  set_color white;
  draw_string "start screen"

let draw_sprites init = 
  Graphics.clear_graph ();
  let light_blue = rgb 76 186 196 in
  set_color (light_blue);
  fill_rect 0 0 600 700;
  set_color black;
  draw_image clarkson 170 300;
  draw_image gries 270 300;
  (* draw_image w_white 370 300; *)
  draw_image camel 370 300;
  set_color red; 
  fill_rect 450 50 100 50;
  set_color white;
  moveto 465 70;
  draw_string "start screen"

(* [draw_update init state] is reponsible for drawing the correct frame, which
   is dependent upon [state] that is represented by a string *)
let draw_update init state = 
  match state with 
  | "go" -> draw_fly init
  | "run" -> draw_run init 
  | "bomb" -> draw_bomb init
  | "death" -> draw_death init 
  | "gameover" -> draw_gameover init 
  | "sprites" -> draw_sprites init 
  | "instructions" -> draw_instructions init 
  | "start" -> draw_start init 
  | "torun" -> draw_fly init 
  | "togo" -> draw_fly init 
  | "tobomb" -> draw_fly init
  | _ -> failwith "draw for this state not impl [draw_update]"
