<?php

function FromTokenToPid(){
    $session_id = session_id();
    global $mysqli;
    $sql = "call TokenToPid(?)";

    $st = $mysqli->prepare($sql);
    $st->bind_param('s', $session_id);
    $st->execute();

    $res = $st->get_result();
    if (mysqli_num_rows($res) == 0) {
        header("HTTP/1.1 400 Bad Request");
        exit;
    }
    $result = $res->fetch_assoc();
    $pid = $result['Pid'];
    $st->close();
    return $pid;
}

function FindWinner(){
    global $mysqli;
    $sql = "CALL FindWinner(?)";
    $st = $mysqli->prepare($sql);

    $st->execute();
    $result = $st->get_result()->fetch_assoc();
    $result = $result['@Winner'];

    $st->close();
    return $result;
}

function PrepareNewGame(){  // DONE.
    global $mysqli;
    $sql = "call PrepareGame()";
    $st = $mysqli->prepare($sql);

    $st->execute();
    $st->close();

}

function AddPlayerIntoGame(){       // DONE.
    $session_id = session_id();
    global $mysqli;
    $st = $mysqli->prepare("call AddPlayer (?, ?, @output)");
    
    $st->bind_param('ss', $GLOBALS['input']['name'], $session_id);
    $st->execute();
    $st->bind_result($result);
    $st->fetch();
    
    $st->close();
    return ['result' => $result];
}

function DealCards(){           // DONE. MIGHT NOT USE
    global $mysqli;
    $sql = "Deal_cards()" ;

    $st = $mysqli->prepare($sql);
    $st->execute();
    $st->close();
}

function TrumpCard(){           // DONE. MIGHT NOT USE
    global $mysqli;
    $sql = "Trump_card()" ;

    $st = $mysqli->prepare($sql);
    $st->execute();
    $st->close();
}

function Place_bets($pid){          // DONE.
    global $mysqli;
    $sql =  'call Place_bets(?, ?, @output)';
    $st = $mysqli->prepare($sql);

    $st->bind_param('ii', $pid, $GLOBALS['input']['bet']);
    $st->execute();
    $result = $st->get_result()->fetch_assoc();

    $st->close();
    return $result;
}

function PlayCards($pid){          // DONE.
    global $mysqli;
    $sql =  'call Play_trick(?, ?, @output)';
    $st = $mysqli->prepare($sql);

    $st->bind_param('ii', $pid, $GLOBALS['input']['c']);
    $st->execute();
    $result = $st->get_result()->fetch_assoc();
    $result = $result['@NotInHand'];

    $st->close();
    return $result;
}

function Show_TrumpClass(){
    global $mysqli;
    $sql = "SELECT Class FROM cards WHERE Pid = 6";
    $st = $mysqli->prepare($sql);
    $st->execute();
    $result = $st->get_result()->fetch_assoc();

    $st->close();
    return $result['Class'];
}

function ShowHand($pid){
    global $mysqli;
    $sql = "call ShowHand(?)";

    $st = $mysqli->prepare($sql);
    $st->bind_param('i', $pid);
    $st->execute();
    $res = $st->get_result();
    $result = json_encode($res->fetch_all(MYSQLI_ASSOC), JSON_PRETTY_PRINT);

    $st->close();
    return $result;
}

function CheckPlayers(){
    global $mysqli;
    $sql = "CALL CheckPlayers(?)";
    $st = $mysqli->prepare($sql);

    $st->execute();
    $result = $st->get_result()->fetch_assoc();
    $result = $result['@playing'];

    $st->close();
    return $result;
    
}

function CheckForWinner(){ // DONE.
    global $mysqli;
    $sql = "CALL Who_won(?)";
    $st = $mysqli->prepare($sql);

    $st->execute();
    $result = $st->get_result()->fetch_assoc();
    $result = $result['@FWinner'];

    $st->close();
    return $result;
}

function SumPoints(){   // DONE.
    global $mysqli;
    $sql = "CALL Sum_points(?)";
    $st = $mysqli->prepare($sql);

    $st->execute();
    $result = $st->get_result()->fetch_assoc();
    $result = $result['@exitcode'];

    $st->close();
    return $result;
}

function FindPlayOrder($pid){
    global $mysqli;
    $sql =  'call CalcPlayOrder(?)';
    $st = $mysqli->prepare($sql);

    $st->bind_param('i', $pid);
    $st->execute();
    $st->close();
}

function AllowedToplay($pid){
    global $mysqli;
    $sql =  'call AllowedToplay(?)';
    $st = $mysqli->prepare($sql);

    $st->bind_param('i', $pid);
    $st->execute();
    $result = $st->get_result()->fetch_assoc();
    $result = $result['@Allowed'];

    $st->close();
    return $result;
}

function GetUsernames(){
    global $mysqli;
    $sql = "SELECT Username FROM players";
    $st = $mysqli->prepare($sql);
    $st->execute();
    $res = $st->get_result();
    header('Content-type: application/json');
    print json_encode($res->fetch_all(MYSQLI_ASSOC), JSON_PRETTY_PRINT);

    $st->close();
}

?>