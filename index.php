<?php
/*
PrepareGame();      EXEI HDH GINEI APO TIN SQL, LIKE THN EXEIS TREKSEI ME TO XERI PIO PRIN.
WHILE Pid<4:
    AddPlayer(Pname, t, Exitcode);

WHILE Round<=15:
    Deal_cards(); Trump_card();

    WHILE Pid<4:
        Place_bet(p, b, exitcode);
    
    WHILE Pid IS NOT NULL (απ' τα χεριά τους):

        IF Card_played ...:

            FindWinner(Exitcode);

    Sum_points();
Who_won();
*/

require_once "lib/db.php";
require_once "lib/functions.php";

$method = $_SERVER['REQUEST_METHOD'];
$request = explode('/', trim($_SERVER['PATH_INFO'], '/'));
$GLOBALS['input'] = json_decode(file_get_contents('php://input'), true);
session_start();

if(CheckPlayers() == 1){    // DEN EXOUN MPEI OLOI OI PAIKTES
    exit;
}

$result = FindWinner();
SumPoints();

$result = CheckForWinner();

if ($result != 5) {
    print json_encode(['winner' => $result]);
    PrepareNewGame();
    exit;
}

switch ($request[0]) {

    // Done
    case 'GetPlayersHand':        
        if ($method == 'GET') {

            $pid = FromTokenToPid();
            print ShowHand($pid);

        } else {
            header("HTTP/1.1 400 Bad Request");
            print json_encode(['errormsg' => "Method $method not allowed here."]);
        }
    break;

    // Done
    case 'AddPlayer':
        if ($method == 'POST') {
            
            if (!isset($GLOBALS['input']['name'])){
                header("HTTP/1.1 400 Bad Request");
                print('Enter username');
                exit();
            }
            
            $result = AddPlayerIntoGame();

            switch ($result['result']) {
                case 1:
                print json_encode(['errormesg' => "Max players"]);
                exit;
                case 2:
                print json_encode(['errormesg' => "Token already exists"]);
                exit;
                default:
                print json_encode(['success'=>"Player added"]);
                }
            
        } else {
            header("HTTP/1.1 400 Bad Request");
            print json_encode(['errormesg' => "Method $method not allowed here."]);
        }
    break;
    
    // DONE!
    case 'PlaceBets':
        if ($method == 'POST'){
            $pid = FromTokenToPid();
            if (!isset($GLOBALS['input']['bet'])) {
                print json_encode(['errormsg' => "You need to bet something."]);
                exit;
            }
            $result = PlaceBets($pid);
            if ($result == 0) {
                print json_encode(['success'=>"Bet added"]);
                exit;
            }
            if ($result == 1) {
                print json_encode(['errormsg' => "Advice: You will lose whatever happens."]);
                exit;
            }
            if ($result == 2){
                print json_encode(['errormsg' => "Error: You already have placed your bet."]);
                exit;
            }
            if ($result == 3){
                print json_encode(['errormsg' => "Error: Place a positive number."]);
                exit;
            }
            
        }else {    
            header("HTTP/1.1 400 Bad Request");
            print json_encode(['errormsg' => "Method $method not allowed here."]);
        }
    break;
    
    // DONE
    case 'PlayCards':
        if ($method == 'POST') {

            $pid = FromTokenToPid();
            $result = AllowedToPlay($pid);

            if ($result == 1) {
                print json_encode(['errormsg' => "Not your turn."]);
            } else {

                if (!isset($GLOBALS['input']['c'])) {
                    print json_encode(['errormsg' => "You need to play something."]);
                    exit;
                }
                $result = PlayCards($pid);
                
                if ($result == 0) {
                    print json_encode(['success'=>"Card played"]);
                    exit;
                }
                if ($result == 2 ) {
                    print json_encode(['errormsg' => "Cards not in player's hand!"]);
                    exit;
                }
                if ($result == 3) {
                    print json_encode(['errormsg' => "Not the appropriate card, play same class!"]);
                    exit;
                }
                if ($result == 4) {
                    print json_encode(['errormsg' => "Wait for all players to place a bet!"]);
                    exit;
                }
                
                FindPlayOrder($pid+1);
            }
        }else {    
            header("HTTP/1.1 400 Bad Request");
            print json_encode(['errormsg' => "Method $method not allowed here."]);
        }
    break;
    // DONE

    case 'GetTrumpClass':
        if ($method == 'GET') {
            print json_encode(['msg' => Show_TrumpClass()]);
        } else {    
            header("HTTP/1.1 400 Bad Request");
            print json_encode(['errormsg' => "Method $method not allowed here."]);
        }
    break;

    case 'GetBoard':
        if ($method == 'GET') {
            print json_encode(['msg' => GetBoard()]);
        } else {    
            header("HTTP/1.1 400 Bad Request");
            print json_encode(['errormsg' => "Method $method not allowed here."]);
        }
    break;

    case 'GetUsernames':
        if ($method == 'GET') {
            print json_encode(['msg' => GetUsernames()]);
        } else {    
            header("HTTP/1.1 400 Bad Request");
            print json_encode(['errormsg' => "Method $method not allowed here."]);
        }
    break;
    
    default:
        header("HTTP/1.1 404 Not Found");
        print json_encode(['errormsg' => "Not found."]);
    break;        
}
?>