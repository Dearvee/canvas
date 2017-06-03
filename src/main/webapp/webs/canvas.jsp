<%--
  Created by IntelliJ IDEA.
  User: Dearvee
  Date: 2017/6/1
  Time: 16:42
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String path = request.getContextPath();
    String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
    Object user=request.getAttribute("user");
    if(user==null)
        out.print("<script>window.location.href=\"../index.jsp\";</script>");
%>
<!DOCTYPE html>
<html>
<head>
    <base href="<%=basePath%>">
    <meta charset="utf-8"/>
    <title>Canvas Edit</title>
    <style>
        html{
            width: 100%;
            height: 100%;
        }
        body{
            width:100%;
            height: 100%;
            overflow: hidden;
            color: #3366CC;
            text-shadow: 0 0 10px #ddd;
            user-select: none;
        }
        h2{
            display: block;
            width: 600px;
            height: 50px;
            margin: 0 auto;
            font-weight: inherit;
            text-align: center;
        }
        .board{
            width:1000px;
            margin: 0 100px;
        }
        .canvas{
            width:1000px;
            height:650px;
            background: #eee;
            float: left;
            box-shadow: 2px 2px 10px #ddd;
            cursor: url("webs/pen.png"),auto;
        }
        .edit{
            height:650px;
            width: 220px;
            display: inline-block;
            position: absolute;
            user-select: none;
            padding: 0;
            margin: 0 10px;
            border: 2px #eeeeee solid;
            list-style: none;
            box-shadow: 0 0 10px #ddd;
        }
        .edit li{
            padding: 5px;
        }
        .chat{
            width: 400px;
            height: 400px;
            background: #dddddd;
            position: fixed;
            bottom: 30px;
            right: 10px;
        }
        .chatInfo{
            width: inherit;
            height: 280px;
            background: #cccccc;
        }
        .chatEdit{
            width: inherit;
            height: 50px;
            position: absolute;
            bottom: 0;
        }
        .chatEdit input:first-child{
            height: 25px;
            width: 250px;
            color: #3366CC;
            margin: 5px 5px;
            font-size: 1em;
        }
    </style>
    <script src="webs/jquery-3.2.1.min.js"></script>
    <script type="text/javascript">
        var websocket = null;

        //判断当前浏览器是否支持WebSocket
        if('WebSocket' in window){
            <%String room=request.getParameter("room");%>
            websocket = new WebSocket("ws://localhost:8080/WebSocket/"+"<%=room%>");//建立连接
        }
        else{
            alert('Not support WebSocket')
        }

        //连接发生错误的回调方法
        websocket.onerror = function(){
            alert("服务器可能开了小差");
        };

        //连接成功建立的回调方法
        websocket.onopen = function(event){
            //alert("Start CanvasGuess");
        }

        //接收到消息的回调方法
        websocket.onmessage = function(event){
            if (event.data.split(":")[0]!=="draw")
                messageFilter(event.data)
        }

        //连接关闭的回调方法
        websocket.onclose = function(){
            //alert("close CanvasGuess");
        }

        //监听窗口关闭事件，当窗口关闭时，主动去关闭websocket连接，防止连接还没断开就关闭窗口，server端会抛异常。
        window.onbeforeunload = function() {
            websocket.close();
        }

        //关闭连接
        function closeWebSocket(){
            websocket.close();
        }

        //发送消息
        function send(info){
            websocket.send(info);
        }

        function messageFilter(message) {//websocket 信息过滤器
            var type=message.split(":")[0];
            var user=message.split(":")[1].split(">>")[0];
            if(type==="draw")
                drawInfo(message);
            if(type==="chat") {
                message=user+" say:<p/>"+message.substring(7+user.length)+"<p/>";
                $("#chatInfo").html($("#chatInfo").html() + message);
            }
            if(type==="guess"){
                message="<猜画> "+user+">><span style='background: #ffffff;padding:5px;border-radius: 5px;'>"+message.substring(8+user.length)+"</span><p/>";
                $("#chatInfo").html($("#chatInfo").html() + message);
            }
            $("#chatInfo").scrollTop($("#chatInfo")[0].scrollHeight);
        }
    </script>
    <script>
        var canDraw = false;
        var drawColor="#000";
        var drawWidth="10";
        var coordinate="";//coordinate-坐标

        function initDraw() {//初始化画笔
            setDrawStyle();
            setDrawType("free");
        }
        function draw(x0, y0, x1, y1) {//画直线
            coordinate=
                "draw:"+drawColor+"+"+drawWidth+"+("+parseInt(x0)+","+
                parseInt(y0)+")"+"("+parseInt(x1)+","+parseInt(y1)+")";
            var co=toCanvasCo(x0,y0,x1,y1);
            x0=co[0];y0=co[1];x1=co[2];y1=co[3];
            var canvas = document.getElementById("canvas");
            var ctx = canvas.getContext("2d");
            ctx.lineWidth = drawWidth;
            ctx.strokeStyle = drawColor;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(x0, y0);
            ctx.lineTo(x1, y1);
            ctx.stroke();
            ctx.closePath();
        }

        function setDrawStyle() {
            var dColor = document.getElementById('drawColor');//画笔颜色
            dColor.oninput = function () {
                drawColor = dColor.value;
            }

            var dView = document.getElementById('viewDWidth');//宽度显示
            var dWidth = document.getElementById('drawWidth');//画笔宽度
            dWidth.oninput = function () {
                drawWidth = dWidth.value;
                dView.innerText = dWidth.value;
            }
        }
        function setDrawType(type) {
            var canvas = document.getElementById("canvas");
            if (type === "free") {//freeDraw
                $("#canvas").bind("mousedown", function (ed) {
                    var beginX = ed.clientX;
                    var beginY = ed.clientY;
                    canDraw = true;
                    $("#canvas").bind("mousemove", function (em) {
                        if (canDraw) {
                            draw(beginX, beginY, em.clientX, em.clientY);
                            send(coordinate);
                            beginX = em.clientX;
                            beginY = em.clientY;
                        }
                        else {
                            beginX = em.clientX;
                            beginY = em.clientY;
                        }
                    });
                });
                $(document.body).bind("mouseup", function () {
                    canDraw = false;
                });
            }
            if (type === "line") {//lineDraw
                var first = true;
                var beginX, beginY, endX, endY;
                $("#canvas").bind("click", function (ec) {
                    if (first) {
                        beginX = ec.clientX;
                        beginY = ec.clientY;
                        endX = ec.clientX;

                        endY = ec.clientY;
                        first = false;
                    }
                    else {
                        endX = ec.clientX;
                        endY = ec.clientY;
                        first = true;
                    }
                    draw(beginX, beginY, endX, endY);
                    send(coordinate);
                });
            }
        }
        function selDrawType() {
            var events=event.srcElement.id;
            alert(events);
            $("#canvas").unbind();
            setDrawType(events);
        }
        function toCanvasCo(x0,y0,x1,y1) {//100 50 相对画板坐标
            return [x0-100, y0-50, x1-100, y1-50];
        }
    </script>
    <script>
        window.onload=function() {
            initDraw();
            $("#chatSend").bind("click",function () {
                send("chat:"+"<%=user%>>>"+$("#inChat").val());
                $("#inChat").val("");
            });
            $("#guessSend").bind("click",function () {
                send("guess:"+"<%=user%>>>"+$("#inChat").val());
                $("#inChat").val("");
            });
            $("#inChat").bind("keypress",function (event) {
                if(event.keyCode===13) {
                    send("chat:"+"<%=user%>>>" + $("#inChat").val());
                    $("#inChat").val("");
                }
            });
        }
    </script>
</head>
<body>
<h2>你是画家，你说了算。</h2>
<div class="board">
    <canvas id="canvas" class="canvas" width="1000" height="650"></canvas>
    <ul class="edit">
        <li>
            <ul style="list-style: none;padding: 0;" onclick="selDrawType();">
                <li>形状</li>
                <p>
                <li id="free" style="display: inline;background: #eee;cursor: pointer;">Free</li>
                <li id="line" style="display: inline;background: #eee;cursor: pointer;">Line</li>
            </ul>
        </li>
        <li>
            <label>宽度:</label>
            <input type="range" id="drawWidth" value="10" min="1" max="100"/>
            <span id="viewDWidth">10</span>
        </li>
        <li>
            <label>颜色:</label>
            <input type="color" id="drawColor"/>
        </li>
    </ul>
</div>
<div class="chat">
    <h3><%=user%> Show time~</h3>
    <div id="chatInfo" class="chatInfo" style="overflow-y: scroll;"></div>
    <div class="chatEdit">
        <input id="inChat" type="text" name="chatInfo" placeholder="聊天/猜画"/>
        <input id="chatSend" type="submit" value="聊天"/>
        <input id="guessSend" type="submit" value="猜画"/>
    </div>
</div>
</body>
</html>

