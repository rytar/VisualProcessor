import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.HashMap;
import java.util.Arrays;
import java.awt.datatransfer.*;
import java.awt.Toolkit;

class Cursor {

    public int line, row;

    Cursor() {
        line = 0;
        row = 0;
    }

    Cursor(int l, int r) {
        line = l;
        row = r;
    }

    @Override
    String toString() {
        return "line: " + line + ", row: " + row;
    }

    boolean gt(Cursor c) {
        if(line > c.line) return true;
        if(line < c.line) return false;
        if(row > c.row) return true;
        return false;
    }

    boolean eq(Cursor c) {
        return line == c.line && row == c.row;
    }

    void next() {
        if(row == s.get(line).length()) {
            if(line < s.size() - 1) {
                row = 0;
                line++;
            }
        }
        else row++;
    }

    void prev() {
        if(row == 0) {
            if(line > 0) {
                line--;
                row = s.get(line).length();
            }
        }
        else row--;
    }

    void up() {
        if(line > 0) {
            line--;
            if(row > s.get(line).length()) row = s.get(line).length();
        }
        else row = 0;
    }

    void down() {
        if(line < s.size() - 1) {
            line++;
            if(row > s.get(line).length()) row = s.get(line).length();
        }
        else row = s.get(line).length();
    }

    void set(int l, int r) {
        line = l;
        row = r;
    }

    void enter() {
        line++;
        row = 0;
    }
}

// let a, a2: int = 0;
// let b: float = 0;
// let c: bool = true;
// let d: string = "Hello";

class Token {
    public String kind, value;

    Token(String k, String v) {
        kind = k;
        value = v;
    }

    @Override
    String toString() {
        return kind + ": " + value;
    }
}

class Lexer {
    private String code;
    public String message;
    private int index, block;
    private boolean stop;
    public ArrayList<Token> result;
    private HashMap<String, Pattern> re;

    Lexer() {
        result = new ArrayList<Token>();
        re = new HashMap<String, Pattern>();
        String space1 = "[ \n\t\r\f]*", space2 = "[ \n\t\r\f]+";
        String id = "[^ \n\t\r\f\\+\\-\\*\\/\\%!\"#\\$&\'\\(\\)=\\^\\|@`\\{\\}:;?<>_,.]+?";
        String expr = ".+?";
        re.put("int", Pattern.compile("^[+-]?\\d+$"));
        re.put("float", Pattern.compile("^[+-]?\\d+\\.\\d+$"));
        re.put("bool", Pattern.compile("^true|false$"));
        re.put("string", Pattern.compile("^\".*?\"$"));
        re.put("let", Pattern.compile("\\A" + space1 + "let" + space2 + id + "(" + space1 + "," + space1 + id + ")*" + space1 + "(:" + space1 + id + ")?" + space1 + "=" + space1 + expr + "(" + space1 + "," + space1 + expr + ")*" + space1 + ";"));
        re.put("let2", Pattern.compile("\\A" + space1 + "let" + space2 + id + "(" + space1 + "," + space1 + id + ")*" + space1 + "(:" + space1 + id + ")?" + space1 + ";"));
        re.put("expr", Pattern.compile("\\A" + space1 + expr + space1 + ";"));
        re.put("funcCall", Pattern.compile("\\A" + space1 + id + "\\(" + "(" + space1 + "\\)" + "|" + space1 + expr + "(" + space1 + "," + space1 + expr + ")*" + space1 + "\\)" + ")" + space1 + ";"));
        re.put("assign", Pattern.compile("\\A" + space1 + id + "(" + space1 + "," + space1 + id + ")*" + space1 + "=" + space1 + expr + "(" + space1 + "," + space1 + expr + ")*" + space1 + ";"));
        re.put("if", Pattern.compile("\\A" + space1 + "if" + space1 + "\\(" + space1 + expr + space1 + "\\)" + space1 + "\\{"));
        re.put("elif", Pattern.compile("\\A" + space1 + "else" + space2 + "if" + space1 + "\\(" + space1 + expr + space1 + "\\)" + space1 + "\\{"));
        re.put("else", Pattern.compile("\\A" + space1 + "else" + space1 + "\\{"));
        re.put("switch", Pattern.compile("\\A" + space1 + "switch" + space1 + "\\(" + space1 + expr + space1 + "\\)" + space1 + "\\{"));
        re.put("while", Pattern.compile("\\A" + space1 + "while" + space2 + expr + space1 + "\\{"));
        re.put("for", Pattern.compile("\\A" + space1 + "for" + space1 + "\\(" + space1 + expr + space1 + ";" + space1 + expr + space1 + ";" + space1 + expr + space1 + "\\)" + space1 + "\\{"));
        re.put("for2", Pattern.compile("\\A" + space1 + "for" + space1 + "\\(" + space1 + "let" + space2 + id + space2 + "in" + space2 + expr + space1 + "\\)" + space1 + "\\{"));
        re.put("func", Pattern.compile("\\A" + space1 + "fn" + space2 + id + "\\(" + "(" + space1 + id + space1 + ":" + space1 + id + "(" + space1 + "," + space1 + id + space1 + ":" + space1 + id + ")*" + ")?" + space1 + "\\)" + space1 + "(" + space1 + "->" + space1 + id + space1 + ")?"+ "\\{"));
        re.put("return", Pattern.compile("\\A" + space1 + "return" + space2 + expr + space1 + ";"));
        re.put("class", Pattern.compile("\\A" + space1 + "class" + space2 + id + space2 + "\\{"));
    }

    public Lexer action(String str) {
        block = 0;
        code = str + " ";
        message = "";
        index = 0;
        stop = false;
        result = new ArrayList<Token>();
        if(code.split("\\{").length != code.split("\\}").length) {
            stop = true;
            return this;
        }
        if(code.split("\\(").length != code.split("\\)").length) {
            stop = true;
            return this;
        }
        result.addAll(statement(code));
        return this;
    }

    private ArrayList<Token> statement(String str) {
        String tmp;
        boolean flag = false;
        Matcher m;
        ArrayList<Token> ret = new ArrayList<Token>();
        int idx = 0;
        ret.add(new Token("stat", "stat"));
        while(!stop && code.length() > index && str.length() > idx) {
            if(block > 0 && code.charAt(index) == '}') {
                block--;
                index++;
                idx++;
                break;
            }
            if(code.length() <= index) break;
            m = Pattern.compile("\\A[ \n\t\r\f]+").matcher(code.substring(index, code.length()));
            if(m.find()) {
                index += m.group().length();
                idx += m.group().length();
                continue;
            }
            tmp = code.substring(index, code.length());

            if(!tmp.contains(";")) {
                stop = true;
                break;
            }

            // claｓs SuperClass {
            //     let a, b;
            // }
            // m = Pattern.compile("\\A[ \n\t\r\f]*class").matcher(tmp);
            // if(m.find()) {
            //     m = re.get("class").matcher(tmp);
            //     if(m.find()) {
            //         String id = m.group().replaceAll("[ \n\t\r\f]*class[ \n\t\r\f]*", "").replaceAll("[ \n\t\r\f]*\\{[ \n\t\r\f]*", "");
            //         ret.add(new Token("class", "class"));
            //         ret.add(new Token("id", id));
            //         index += m.group().length();
            //         idx += m.group().length();
            //         block++;
            //         ret.addAll(classStat(id, code.substring(index, code.length())));
            //         idx += index - idx;
            //         continue;
            //     }
            // }

            // fn func(a: int, b: int) -> int {
            //     println(a, b);
            //     return 0;
            // }
            // 
            // fn: fn, id: func, retType: int, args: args, id: a, type: int, id: b, type: int, endArgs: endArgs, stat: stat,
            //     funcCall: funcCall, id: println, expr: expr, id: a, endExpr: endExpr, expr: expr, id: b, endExpr: endExpr, endFuncCall: endFuncCall,
            //     return: return, expr: expr, int: 0, endExpr: endExpr, endReturn: endReturn,
            // endStat: endStat, endFn: endFn
            m = Pattern.compile("\\A[ \n\t\r\f]*fn").matcher(tmp);
            if(m.find()) {
                m = re.get("func").matcher(tmp);
                if(m.find()) {
                    String ss = m.group().replaceAll("[ \n\t\r\f]*fn[ \n\t\r\f]*", "");
                    String[] target = new String[4];
                    target[0] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[0];
                    target[1] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*")[0];
                    if(ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*").length == 2) target[2] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*")[1].replaceAll("[ \n\t\r\f]*\\->[ \n\t\r\f]*", "").split("[ \n\t\r\f]*\\{")[0];
                    ret.add(new Token("fn", "fn"));
                    ret.add(new Token("id", target[0]));
                    if(target.length >= 3) ret.add(new Token("retType", target[2]));
                    ret.add(new Token("args", "args"));
                    if(target[1].length() > 0) {
                        String[] args = target[1].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
                        for(int i = 0; i < args.length; i++) {
                            ret.add(new Token("id", args[i].split("[ \n\t\r\f]*:[ \n\t\r\f]*")[0]));
                            ret.add(new Token("type", args[i].split("[ \n\t\r\f]*:[ \n\t\r\f]*")[1]));
                        }
                    }
                    ret.add(new Token("endArgs", "endArgs"));
                    index += m.group().length();
                    idx += m.group().length();
                    block++;
                    int prevIndex = index;
                    ret.addAll(statement(code.substring(index, code.length())));
                    idx += index - prevIndex;
                    ret.add(new Token("endFn", "endFn"));
                    continue;
                }
                else {
                    stop = true;
                    break;
                }
            }

            m = re.get("return").matcher(tmp);
            if(m.find()) {
                String expr = m.group().replaceAll("^[ \n\t\r\f]*return[ \n\t\r\f]+", "").replaceAll("[ \n\t\r\f]*;[ \n\t\r\f]*$", "");
                ret.add(new Token("return", "return"));
                ret.addAll(expression(expr));
                index += m.group().length();
                idx += m.group().length();
                continue;
            }

            // if a != 0 {
            //     println(a);
            // }
            // if: if, expr: expr, id: a, neq: !=, int: 0, endExpr: endExpr, stat: stat, funcCall, id: println, expr: expr, id: a, endExpr: endExpr, endFuncCall: endFuncCall, endStat: endStat, endIf: endIf
            m = Pattern.compile("\\A[ \n\t\r\f]*if").matcher(tmp);
            if(m.find()) {
                m = re.get("if").matcher(tmp);
                if(m.find()) {
                    String expr = m.group().replaceAll("[ \n\t\r\f]*if[ \n\t\r\f]*\\([ \n\t\r\f]*", "").replaceAll("[ \n\t\r\f]*\\)[ \n\t\r\f]*\\{", "");
                    ret.add(new Token("if", "if"));
                    ret.addAll(expression(expr));
                    index += m.group().length();
                    idx += m.group().length();
                    block++;
                    int prevIndex = index;
                    ret.addAll(statement(code.substring(index, code.length())));
                    idx += index - prevIndex;
                    m = re.get("elif").matcher(code.substring(index, code.length()));
                    while(code.length() > index && m.find()) {
                        expr = m.group().replaceAll("[ \n\t\r\f]*else[ \n\t\r\f]+if[ \n\t\r\f]*\\([ \n\t\r\f]*", "").replaceAll("[ \n\t\r\f]*\\)[ \n\t\r\f]*\\{", "");
                        ret.add(new Token("elif", "elif"));
                        ret.addAll(expression(expr));
                        index += m.group().length();
                        idx += m.group().length();
                        block++;
                        prevIndex = index;
                        ret.addAll(statement(code.substring(index, code.length())));
                        idx += index - prevIndex;
                        m = re.get("elif").matcher(code.substring(index, code.length()));
                    }
                    m = re.get("else").matcher(code.substring(index, code.length()));
                    if(m.find()) {
                        ret.add(new Token("else", "else"));
                        index += m.group().length();
                        idx += m.group().length();
                        block++;
                        prevIndex = index;
                        ret.addAll(statement(code.substring(index, code.length())));
                        idx += index - prevIndex;
                    }
                    ret.add(new Token("endIf", "endIf"));
                    continue;
                }
                else {
                    stop = true;
                    break;
                }
            }

            m = Pattern.compile("\\A[ \n\t\r\f]*switch").matcher(tmp);
            if(m.find()) {
                m = re.get("switch").matcher(tmp);
                if(m.find()) {
                    String expr = m.group().replaceAll("[ \n\t\r\f]*switch[ \n\t\r\f]*\\(", "").replaceAll("[ \n\t\r\f]*\\)[ \n\t\r\f]*\\{", "");
                    ret.add(new Token("switch", "switch"));
                    ret.addAll(expression(expr));
                    index += m.group().length();
                    idx += m.group().length();
                    ret.addAll(switchcase(code.substring(index, code.length())));
                    idx += index - idx;
                    ret.add(new Token("endSwitch", "endSwitch"));
                    continue;
                }
            }

            m = Pattern.compile("\\A[ \n\t\r\f]*while").matcher(tmp);
            if(m.find()) {
                m = re.get("while").matcher(tmp);
                if(m.find()) {
                    String expr = m.group().replaceAll("[ \n\t\r\f]*while[ \n\t\r\f]*\\([ \n\t\r\f]*", "").replaceAll("[ \n\t\r\f]*\\)[ \n\t\r\f]*\\{", "");
                    ret.add(new Token("while", "while"));
                    ret.addAll(expression(expr));
                    index += m.group().length();
                    idx += m.group().length();
                    block++;
                    int prevIndex = index;
                    ret.addAll(statement(code.substring(index, code.length())));
                    idx += index - prevIndex;
                    ret.add(new Token("endWhile", "endWhile"));
                    continue;
                }
                else {
                    stop = true;
                    break;
                }
            }

            m = Pattern.compile("\\A[ \n\t\r\f]*for").matcher(tmp);
            if(m.find()) {
                // for(let i: int = 0; i < 10; i++) {}
                m = re.get("for").matcher(tmp);
                if(m.find()) {
                    String[] stats = m.group().replaceAll("[ \n\t\r\f]*for[ \n\t\r\f]*\\([ \n\t\r\f]*", "").replaceAll("[ \n\t\r\f]*\\)[ \n\t\r\f]*\\{", "").split("[ \n\t\r\f]*;[ \n\t\r\f]*");
                    if(stats.length != 3) {
                        stop = false;
                        break;
                    }
                    String mgroup = m.group();
                    m = Pattern.compile("\\A[ \n\t\r\f]*for[ \n\t\r\f]*\\([ \n\t\r\f]*").matcher(mgroup);
                    m.find();
                    index += m.group().length();
                    idx += m.group().length();
                    ret.add(new Token("for", "for"));
                    int prevIndex = index;
                    ret.addAll(statement(stats[0]));
                    idx += index - prevIndex;
                    ret.addAll(expression(stats[1]));
                    ret.addAll(expression(stats[2]));
                    index += mgroup.length() - m.group().length() - stats[0].length();
                    idx += mgroup.length() - m.group().length() - stats[0].length();
                    block++;
                    prevIndex = index;
                    ret.addAll(statement(code.substring(index, code.length())));
                    idx += index - prevIndex;
                    ret.add(new Token("endFor", "endFor"));
                    continue;
                }
                else {
                    // for(let i in range(10)) {}
                    m = re.get("for2").matcher(tmp);
                    if(m.find()) {
                        ;
                    }
                }
            }

            // let a, b: int = 0, 9;
            // -> let: let, type: int, id: a, id: b, expr: expr, int: 0, endExpr: endExpr, expr: expr, int: 9, exdExpr: endExpr, endLet: endLet
            m = Pattern.compile("\\A[ \n\t\r\f]*let").matcher(tmp);
            if(m.find()) {
                m = re.get("let").matcher(tmp);
                if(m.find()) {
                    ret.addAll(let(m.group()));
                    index += m.group().length();
                    idx += m.group().length();
                    continue;
                }
                else {
                    m = re.get("let2").matcher(tmp);
                    if(m.find()) {
                        String[] target = m.group().replaceAll("^[ \n\t\r\f]*let[ \n\t\r\f]*", "").replaceAll("[ \n\t\r\f]*;[ \n\t\r\f]*$", "").split("[ \n\t\r\f]*:[ \n\t\r\f]*");
                        ret.add(new Token("let", "let"));
                        if(target.length == 2) {
                            String[] ids = target[0].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
                            String type = target[1];
                            ret.add(new Token("type", type));
                            for(int i = 0; i < ids.length; i++) ret.add(new Token("id", ids[i]));
                            ret.add(new Token("expr", "expr"));
                            ret.add(new Token("null", "null"));
                            ret.add(new Token("endExpr", "endExpr"));
                        }
                        else if(target.length == 1) {
                            String[] ids = target[0].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
                            for(int i = 0; i < ids.length; i++) ret.add(new Token("id", ids[i]));
                            ret.add(new Token("expr", "expr"));
                            ret.add(new Token("null", "null"));
                            ret.add(new Token("endExpr", "endExpr"));
                        }
                        ret.add(new Token("endLet", "endLet"));
                        index += m.group().length();
                        idx += m.group().length();
                        continue;
                    }
                    else {
                        stop = true;
                        break;
                    }
                }
            }

            m = Pattern.compile("\\A[ \n\t\r\f]*(for|while|let|fn|if)").matcher(tmp);
            if(!m.find()) {
                m = re.get("assign").matcher(tmp);
                if(m.find()) {
                    ret.addAll(assign(m.group()));
                    index += m.group().length();
                    idx += m.group().length();
                    continue;
                }

                m = re.get("funcCall").matcher(tmp);
                if(m.find()) {
                    ret.addAll(function_call(m.group().replaceAll("[ \n\t\r\f]*;", "")));
                    index += m.group().length();
                    idx += m.group().length();
                    continue;
                }

                m = re.get("expr").matcher(tmp);
                if(m.find()) {
                    ret.addAll(expression(m.group().replaceAll("[ \n\t\r\f]*;", "")));
                    index += m.group().length();
                    idx += m.group().length();
                    continue;
                }
            }

            stop = true;
        }
        ret.add(new Token("endStat", "endStat"));
        return ret;
    }

    // private ArrayList<Token> classStat(String name, String str) {
    //     ArrayList<Token> ret = new ArrayList<Token>();
    //     Matcher m;
    //     String tmp = "";
    //     int idx = 0;
    //     ret.add(new Token("stat", "stat"));
    //     while(!stop && code.length() > index && str.length() > idx) {
    //         if(block > 0 && code.charAt(index) == '}') {
    //             block--;
    //             index++;
    //             idx++;
    //             break;
    //         }
    //         if(code.length() <= index) break;
    //         m = Pattern.compile("\\A[ \n\t\r\f]+").matcher(code.substring(index, code.length()));
    //         if(m.find()) {
    //             index += m.group().length();
    //             idx += m.group().length();
    //             continue;
    //         }
    //         tmp = code.substring(index, code.length());

    //         m = Pattern.compile("\\A[ \n\t\r\f]*let").matcher(tmp);
    //         if(m.find()) {
    //             m = re.get("let").matcher(tmp);
    //             if(m.find()) {
    //                 ret.addAll(let(m.group()));
    //                 index += m.group().length();
    //                 idx += m.group().length();
    //                 continue;
    //             }
    //             else {
    //                 m = re.get("let2").matcher(tmp);
    //                 if(m.find()) {
    //                     String[] target = m.group().replaceAll("^[ \n\t\r\f]*let[ \n\t\r\f]*", "").replaceAll("[ \n\t\r\f]*;[ \n\t\r\f]*$", "").split("[ \n\t\r\f]*:[ \n\t\r\f]*");
    //                     ret.add(new Token("let", "let"));
    //                     if(target.length == 2) {
    //                         String[] ids = target[0].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
    //                         String type = target[1];
    //                         ret.add(new Token("type", type));
    //                         for(int i = 0; i < ids.length; i++) ret.add(new Token("id", ids[i]));
    //                         ret.add(new Token("expr", "expr"));
    //                         ret.add(new Token("null", "null"));
    //                         ret.add(new Token("endExpr", "endExpr"));
    //                     }
    //                     else if(target.length == 1) {
    //                         String[] ids = target[0].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
    //                         for(int i = 0; i < ids.length; i++) ret.add(new Token("id", ids[i]));
    //                         ret.add(new Token("expr", "expr"));
    //                         ret.add(new Token("null", "null"));
    //                         ret.add(new Token("endExpr", "endExpr"));
    //                     }
    //                     ret.add(new Token("endLet", "endLet"));
    //                     index += m.group().length();
    //                     idx += m.group().length();
    //                     continue;
    //                 }
    //                 else {
    //                     stop = true;
    //                     break;
    //                 }
    //             }
    //         }

    //         m = re.get("func").matcher(tmp);
    //         if(m.find()) {
    //             String ss = m.group().replaceAll("[ \n\t\r\f]*fn[ \n\t\r\f]*", "");
    //             String[] target = new String[4];
    //             target[0] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[0];
    //             target[1] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*")[0];
    //             if(ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*").length == 2) target[2] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*")[1].replaceAll("[ \n\t\r\f]*\\->[ \n\t\r\f]*", "").split("[ \n\t\r\f]*\\{")[0];
    //             ret.add(new Token("fn", "fn"));
    //             ret.add(new Token("id", target[0]));
    //             if(target.length == 3) ret.add(new Token("retType", target[2]));
    //             ret.add(new Token("args", "args"));
    //             if(target[1].length() > 0) {
    //                 String[] args = target[1].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
    //                 for(int i = 0; i < args.length; i++) {
    //                     ret.add(new Token("id", args[i].split("[ \n\t\r\f]*:[ \n\t\r\f]*")[0]));
    //                     ret.add(new Token("type", args[i].split("[ \n\t\r\f]*:[ \n\t\r\f]*")[1]));
    //                 }
    //             }
    //             ret.add(new Token("endArgs", "endArgs"));
    //             index += m.group().length();
    //             idx += m.group().length();
    //             block++;
    //             ret.addAll(statement(code.substring(index, code.length())));
    //             idx += index - idx;
    //             ret.add(new Token("endFn", "endFn"));
    //             continue;
    //         }

    //         m = Pattern.compile("\\A[ \n\t\r\f]*" + name + "[ \n\t\r\f]*\\(([ \n\t\r\f]*[^ \n\t\r\f\\+\\-\\*\\/\\%!\"#\\$&\'\\(\\)=\\^\\|@`\\{\\}:;?<>_,.]+?[ \n\t\r\f]*:[ \n\t\r\f]*[^ \n\t\r\f\\+\\-\\*\\/\\%!\"#\\$&\'\\(\\)=\\^\\|@`\\{\\}:;?<>_,.]+?([ \n\t\r\f]*,[ \n\t\r\f]*[^ \n\t\r\f\\+\\-\\*\\/\\%!\"#\\$&\'\\(\\)=\\^\\|@`\\{\\}:;?<>_,.]+?[ \n\t\r\f]*:[ \n\t\r\f]*[^ \n\t\r\f\\+\\-\\*\\/\\%!\"#\\$&\'\\(\\)=\\^\\|@`\\{\\}:;?<>_,.]+?)*)?[ \n\t\r\f]*\\)[ \n\t\r\f]*\\{").matcher(tmp);
    //         if(m.find()) {
    //             String ss = m.group().replaceAll("\\A[ \n\t\r\f]*", "");
    //             String[] target = new String[4];
    //             target[0] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[0];
    //             target[1] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*")[0];
    //             if(ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*").length == 2) target[2] = ss.split("[ \n\t\r\f]*\\([ \n\t\r\f]*")[1].split("[ \n\t\r\f]*\\)[ \n\t\r\f]*")[1].replaceAll("[ \n\t\r\f]*\\->[ \n\t\r\f]*", "").split("[ \n\t\r\f]*\\{")[0];
    //             ret.add(new Token("constructor", "constructor"));
    //             ret.add(new Token("id", target[0]));
    //             if(target.length == 3) ret.add(new Token("retType", target[2]));
    //             ret.add(new Token("args", "args"));
    //             if(target[1].length() > 0) {
    //                 String[] args = target[1].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
    //                 for(int i = 0; i < args.length; i++) {
    //                     ret.add(new Token("id", args[i].split("[ \n\t\r\f]*:[ \n\t\r\f]*")[0]));
    //                     ret.add(new Token("type", args[i].split("[ \n\t\r\f]*:[ \n\t\r\f]*")[1]));
    //                 }
    //             }
    //             ret.add(new Token("endArgs", "endArgs"));
    //             index += m.group().length();
    //             idx += m.group().length();
    //             block++;
    //             ret.addAll(statement(code.substring(index, code.length())));
    //             idx += index - idx;
    //             ret.add(new Token("endConstructor", "endConstructor"));
    //             continue;
    //         }

    //         stop = true;
    //     }
    //     return ret;
    // }

    // switch(arr[i]) {
    //     case 0:
    //         println(0);
    //     case 1:
    //         println(2);
    //     default:
    //         println(4);
    // }
    // switch: switch, expr: expr, id: arr, lsb: [, id: i, rsb: ], endExpr: endExpr,
    //     case: case, expr: expr, int: 0, endExpr: endExpr, stat: stat, funcCall: funcCall, id: println, expr: expr, int: 0, endExpr: endExpr, endFuncCall: endFuncCall, endStat: endStat,
    //     case: 1, stat: stat, funcCall: funcCall, id: println, expr: expr, int: 1, endExpr: endExpr, endFuncCall: endFuncCall, endStat: endStat,
    //     default: default, stat: stat, funcCall: funcCall, id: println, expr: expr, int: 1, endExpr: endExpr, endFuncCall: endFuncCall, endStat: endStat,
    // endSwitch: endSwitch
    private ArrayList<Token> switchcase(String str) {
        ArrayList<Token> ret = new ArrayList<Token>();
        Matcher m;
        String tmp = "";
        int idx = 0;
        while(!stop && code.length() > index && str.length() > idx) {
            tmp = code.substring(index, code.length());
            m = Pattern.compile("\\A[ \n\t\r\f]*case[ \n\t\r\f]*.+?[ \n\t\r\f]*:").matcher(tmp);
            if(m.find()) {
                String expr = m.group().replaceAll("[ \n\t\r\f]*case[ \n\t\r\f]*", "").replaceAll("[ \n\t\r\f]*:", "");
                ret.add(new Token("case", "case"));
                ret.addAll(expression(expr));
                index += m.group().length();
                idx += m.group().length();
                tmp = code.substring(index, code.length());
                m = Pattern.compile("case|default").matcher(tmp);
                if(m.find()) {
                    String s = tmp.split("case|default")[0];
                    int prevIndex = index;
                    ret.addAll(statement(s));
                    idx += index - prevIndex;
                    continue;
                }
                else {
                    block++;
                    int prevIndex = index;
                    ret.addAll(statement(code.substring(index, code.length())));
                    idx += index - prevIndex;
                    break;
                }
            }
            m = Pattern.compile("\\A[ \n\t\r\f]*default[ \n\t\r\f]*:").matcher(tmp);
            if(m.find()) {
                ret.add(new Token("default", "default"));
                index += m.group().length();
                idx += m.group().length();
                int prevIndex = index;
                ret.addAll(statement(code.substring(index, code.length())));
                idx += index - prevIndex;
                break;
            }
            stop = true;
        }
        return ret;
    }

    private ArrayList<Token> let(String str) {
        String[] target = new String[3];
        str = str.replaceFirst("[ \n\t\r\f]*let[ \n\t\r\f]+", "");
        int n = str.split("[ \n\t\r\f]*:[ \n\t\r\f]*[^ \n\t\r\f\\+\\-\\*\\/\\%!\"#\\$&\'\\(\\)=\\^\\|@`\\{\\}:;?<>_,.]+?[ \n\t\r\f]*=[ \n\t\r\f]*").length;
        if(n == 2) {
            target[0] = str.split("[ \n\t\r\f]*:[ \n\t\r\f]*", 2)[0];
            target[1] = str.split("[ \n\t\r\f]*:[ \n\t\r\f]*", 2)[1].split("[ \n\t\r\f]*=[\n\t\r\f]*", 2)[0];
            target[2] = str.split("[ \n\t\r\f]*:[ \n\t\r\f]*", 2)[1].split("[ \n\t\r\f]*=[\n\t\r\f]*", 2)[1].replaceAll("[ \n\t\r\f]*;[ \n\t\r\f]*", "");
        }
        else if(n == 1) {
            target[0] = str.split("[ \n\t\r\f]*=[\n\t\r\f]*", 2)[0];
            target[2] = str.split("[ \n\t\r\f]*=[\n\t\r\f]*", 2)[1].replaceAll("[ \n\t\r\f]*;[ \n\t\r\f]*", "");
        }
        ArrayList<Token> ret = new ArrayList<Token>();
        if(n % 2 == 0) {
            ret.add(new Token("let", "let"));
            ret.add(new Token("type", target[1]));
            String[] ids = target[0].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
            for(int i = 0; i < ids.length; i++) ret.add(new Token("id", ids[i]));
            ArrayList<String> vals = new ArrayList<String>();
            String tmp = "";
            boolean flag1 = false;
            int f2 = 0, f3 = 0;
            for(int i = 0; i < target[2].length(); i++) {
                if(target[2].charAt(i) == '\"') {
                    flag1 = !flag1;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && target[2].charAt(i) == '(') {
                    f2++;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && target[2].charAt(i) == ')') {
                    f2--;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && target[2].charAt(i) == '{') {
                    f3++;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && target[2].charAt(i) == '}') {
                    f3--;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && f2 == 0 && f3 == 0 && target[2].charAt(i) == ',') {
                    vals.add(tmp);
                    tmp = "";
                }
                else if(flag1 || target[2].charAt(i) != ' ') tmp += target[2].charAt(i);
            }
            if(!tmp.isEmpty()) {
                vals.add(tmp);
                tmp = "";
            }
            if(flag1 || f2 != 0 || f3 != 0) {
                stop = true;
            }
            for(String val: vals) {
                ret.addAll(expression(val));
            }
            ret.add(new Token("endLet", "endLet"));
        }
        else {
            ret.add(new Token("let", "let"));
            String[] ids = target[0].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
            for(int i = 0; i < ids.length; i++) ret.add(new Token("id", ids[i]));
            ArrayList<String> vals = new ArrayList<String>();
            String tmp = "";
            boolean flag1 = false;
            int f2 = 0, f3 = 0;
            for(int i = 0; i < target[2].length(); i++) {
                if(target[2].charAt(i) == '\"') {
                    flag1 = !flag1;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && target[2].charAt(i) == '(') {
                    f2++;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && target[2].charAt(i) == ')') {
                    f2--;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && target[2].charAt(i) == '{') {
                    f3++;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && target[2].charAt(i) == '}') {
                    f3--;
                    tmp += target[2].charAt(i);
                }
                else if(!flag1 && f2 == 0 && f3 == 0 && target[2].charAt(i) == ',') {
                    vals.add(tmp);
                    tmp = "";
                }
                else if(flag1 || target[2].charAt(i) != ' ') tmp += target[2].charAt(i);
            }
            if(!tmp.isEmpty()) {
                vals.add(tmp);
                tmp = "";
            }
            if(flag1 || f2 != 0 || f3 != 0) {
                stop = true;
            }
            for(String val: vals) {
                ret.addAll(expression(val));
            }
            ret.add(new Token("endLet", "endLet"));
        }
        return ret;
    }

    private ArrayList<Token> assign(String str) {
        String[] target = str.split("[ \n\t\r\f]*=[ \n\t\r\f]*");
        String[] ids = target[0].split("[ \n\t\r\f]*,[ \n\t\r\f]*");
        ArrayList<Token> ret = new ArrayList<Token>();
        ret.add(new Token("assign", "assign"));
        for(int i = 0; i < ids.length; i++) ret.add(new Token("id", ids[i].replaceAll("[ \n\t\r\f]*", "")));
        ArrayList<String> vals = new ArrayList<String>();
        String tmp = "";
        boolean flag1 = false, flag2 = false, flag3 = false;
        for(int i = 0; i < target[1].length(); i++) {
            if(target[1].charAt(i) == '\"') {
                flag1 = !flag1;
                tmp += target[1].charAt(i);
            }
            else if(!flag1 && target[1].charAt(i) == '(') {
                flag2 = !flag2;
                tmp += target[1].charAt(i);
            }
            else if(!flag1 && target[1].charAt(i) == ')') {
                flag2 = !flag2;
                tmp += target[1].charAt(i);
            }
            else if(!flag1 && target[1].charAt(i) == '{') {
                flag3 = !flag3;
                tmp += target[1].charAt(i);
            }
            else if(!flag1 && target[1].charAt(i) == '}') {
                flag3 = !flag3;
                tmp += target[1].charAt(i);
            }
            else if(!flag1 && !flag2 && !flag3 && target[1].charAt(i) == ',') {
                vals.add(tmp);
                tmp = "";
            }
            else if(flag1 || target[1].charAt(i) != ' ') tmp += target[1].charAt(i);
        }
        if(!tmp.isEmpty()) {
            vals.add(tmp);
            tmp = "";
        }
        if(flag1 || flag2 || flag3) {
            stop = true;
        }
        for(String val: vals) {
            ret.addAll(expression(val));
        }
        ret.add(new Token("endAssign", "endAssign"));
        return ret;
    }

    // println("Count: " + count1, 10)
    // -> funcCall: funcCall, id: println, expr: expr, string: "Count: ", add: +, id: count1, endExpr: endExpr, expr: expr, int: 10, endExpr: endExpr, endFuncCall: endFuncCall
    private ArrayList<Token> function_call(String str) {
        String[] s = str.replaceAll("[ \n\t\r\f]*\\)[ \n\t\r\f]*$", "").split("\\([ \n\t\r\f]*", 2);
        ArrayList<Token> ret = new ArrayList<Token>();
        ret.add(new Token("funcCall", "funcCall"));
        ret.add(new Token("id", s[0].replaceAll("[ \n\t\r\f]*", "")));
        if(s.length < 2) {
            stop = true;
            return ret;
        }
        if(s[1].length() > 0) {
            ArrayList<String> vals = new ArrayList<String>();
            String tmp = "";
            boolean flag1 = false, flag2 = false, flag3 = false;
            for(int i = 0; i < s[1].length(); i++) {
                if(s[1].charAt(i) == '\"') {
                    flag1 = !flag1;
                    tmp += s[1].charAt(i);
                }
                else if(!flag1 && s[1].charAt(i) == '(') {
                    flag2 = !flag2;
                    tmp += s[1].charAt(i);
                }
                else if(!flag1 && s[1].charAt(i) == ')') {
                    flag2 = !flag2;
                    tmp += s[1].charAt(i);
                }
                else if(!flag1 && s[1].charAt(i) == '{') {
                    flag3 = !flag3;
                    tmp += s[1].charAt(i);
                }
                else if(!flag1 && s[1].charAt(i) == '}') {
                    flag3 = !flag3;
                    tmp += s[1].charAt(i);
                }
                else if(!flag1 && !flag2 && !flag3 && s[1].charAt(i) == ',') {
                    vals.add(tmp);
                    tmp = "";
                }
                else if(flag1 || s[1].charAt(i) != ' ') tmp += s[1].charAt(i);
            }
            if(!tmp.isEmpty()) {
                vals.add(tmp);
                tmp = "";
            }
            if(flag1 || flag2 || flag3) {
                stop = true;
            }
            for(String val: vals) {
                ret.addAll(expression(val));
            }
        }
        ret.add(new Token("endFuncCall", "endFuncCall"));
        return ret;
    }

    // 100 * (30 + 20) - a / 2
    // -> expr: expr, int: 100, mul: *, lp: (, int: 30, add: +, int: 20, rp: ), sub: -, id: a, div: /, int: 2, endExpr: endExpr
    // "Hello" + "World"
    // -> expr: expr, string: "Hello", add: +, string: "World", endExpr: endExpr
    private ArrayList<Token> expression(String str) {
        ArrayList<String> strs = new ArrayList<String>();
        String tmp = "";
        Boolean flag = false;
        Matcher m;
        for(int i = 0; i < str.length(); i++) {
            if(str.charAt(i) == '\"') {
                if(flag) {
                    tmp += str.charAt(i);
                    strs.add(tmp);
                    tmp = "";
                }
                else {
                    if(!tmp.isEmpty()) {
                        strs.add(tmp);
                        tmp = "";
                    }
                    tmp += str.charAt(i);
                }
                flag = !flag;
            }
            else {
                if(flag || str.charAt(i) != ' ') tmp += str.charAt(i);
            }
        }
        if(!tmp.isEmpty()) strs.add(tmp);
        ArrayList<String> s = new ArrayList<String>();
        for(int i = 0; i < strs.size(); i++) {
            m = re.get("string").matcher(strs.get(i));
            if(m.find()) {
                s.add(m.group());
            }
            else {
                s.addAll(
                    Arrays.asList(
                        strs.get(i).replaceAll("\\A[ \n\t\r\f]*", "")
                                .replaceAll("[ \n\t\r\f]*;[ \n\t\r\f]*", "")
                                .replaceAll("[ \n\t\r\f]*\\([ \n\t\r\f]*", "@(@")
                                .replaceAll("[ \n\t\r\f]*\\)[ \n\t\r\f]*", "@)@")
                                .replaceAll("[ \n\t\r\f]*\\{[ \n\t\r\f]*", "@{@")
                                .replaceAll("[ \n\t\r\f]*\\}[ \n\t\r\f]*", "@}@")
                                .replaceAll("[ \n\t\r\f]*\\[[ \n\t\r\f]*", "@[@")
                                .replaceAll("[ \n\t\r\f]*\\][ \n\t\r\f]*", "@]@")
                                .replaceAll("[ \n\t\r\f]*\\+[ \n\t\r\f]*", "@+@")
                                .replaceAll("[ \n\t\r\f]*@\\+@@\\+@[ \n\t\r\f]*", "@++@")
                                .replaceAll("[ \n\t\r\f]*\\-[ \n\t\r\f]*", "@-@")
                                .replaceAll("[ \n\t\r\f]*@\\-@@\\-@[ \n\t\r\f]*", "@--@")
                                .replaceAll("[ \n\t\r\f]*\\*[ \n\t\r\f]*", "@*@")
                                .replaceAll("[ \n\t\r\f]*\\/[ \n\t\r\f]*", "@/@")
                                .replaceAll("[ \n\t\r\f]*\\%[ \n\t\r\f]*", "@%@")
                                .replaceAll("[ \n\t\r\f]*&&[ \n\t\r\f]*", "@&&@")
                                .replaceAll("[ \n\t\r\f]*\\|\\|[ \n\t\r\f]*", "@||@")
                                .replaceAll("[ \n\t\r\f]*<[ \n\t\r\f]*", "@<@")
                                .replaceAll("[ \n\t\r\f]*@<@=[ \n\t\r\f]*", "@<=@")
                                .replaceAll("[ \n\t\r\f]*>[ \n\t\r\f]*", "@>@")
                                .replaceAll("[ \n\t\r\f]*@>@=[ \n\t\r\f]*", "@>=@")
                                .replaceAll("[ \n\t\r\f]*==[ \n\t\r\f]*", "@==@")
                                .replaceAll("[ \n\t\r\f]*!=[ \n\t\r\f]*", "@!=@")
                                .replaceAll("@@", "@")
                                .split("@")
                    )
                );
            }
        }
        if(s.get(0).isEmpty()) s.remove(0);
        ArrayList<Token> ret = new ArrayList<Token>();
        ret.add(new Token("expr", "expr"));
        for(int i = 0; i < s.size(); i++) {
            m = re.get("string").matcher(s.get(i));
            if(m.find()) {
                ret.add(new Token("string", m.group()));
                continue;
            }
            if(s.get(i).equals("(")) ret.add(new Token("lp", s.get(i)));
            else if(s.get(i).equals(")")) ret.add(new Token("rp", s.get(i)));
            else if(s.get(i).equals("[")) ret.add(new Token("lsb", s.get(i)));
            else if(s.get(i).equals("]")) ret.add(new Token("rsb", s.get(i)));
            else if(s.get(i).equals("++")) ret.add(new Token("inc", s.get(i)));
            else if(s.get(i).equals("+")) ret.add(new Token("add", s.get(i)));
            else if(s.get(i).equals("--")) ret.add(new Token("dec", s.get(i)));
            else if(s.get(i).equals("-")) ret.add(new Token("sub", s.get(i)));
            else if(s.get(i).equals("*")) ret.add(new Token("mul", s.get(i)));
            else if(s.get(i).equals("/")) ret.add(new Token("div", s.get(i)));
            else if(s.get(i).equals("%")) ret.add(new Token("mod", s.get(i)));
            else if(s.get(i).equals("&&")) ret.add(new Token("and", s.get(i)));
            else if(s.get(i).equals("||")) ret.add(new Token("or", s.get(i)));
            else if(s.get(i).equals("<=")) ret.add(new Token("lte", s.get(i)));
            else if(s.get(i).equals("<")) ret.add(new Token("lt", s.get(i)));
            else if(s.get(i).equals(">=")) ret.add(new Token("gte", s.get(i)));
            else if(s.get(i).equals(">")) ret.add(new Token("gt", s.get(i)));
            else if(s.get(i).equals("==")) ret.add(new Token("eq", s.get(i)));
            else if(s.get(i).equals("!=")) ret.add(new Token("neq", s.get(i)));
            else if(s.get(i).equals("{")) {
                i++;
                ret.add(new Token("arr", "arr"));
                if(s.get(i).equals("}")) {
                    ret.add(new Token("endArr", "endArr"));
                    continue;
                }
                ArrayList<String> vals = new ArrayList<String>();
                tmp = "";
                flag = false;
                int fff = 0;
                // "{", "{", "1, 2", "}", ",", "{", "2, 3", "}", "}"
                while(i < s.size() && !s.get(i).equals("}") || fff > 0) {
                    if(s.get(i).equals("{")) fff++;
                    if(s.get(i).equals("}")) fff--;
                    for(int j = 0; j < s.get(i).length(); j++) {
                        if(s.get(i).charAt(j) == '\"' && fff == 0) {
                            flag = !flag;
                            tmp += s.get(i).charAt(j);
                        }
                        else if(!flag && s.get(i).charAt(j) == ',' && fff == 0) {
                            vals.add(tmp);
                            tmp = "";
                        }
                        else tmp += s.get(i).charAt(j);
                    }
                    i++;
                    if(flag) {
                        stop = true;
                        return ret;
                    }
                }
                if(!tmp.isEmpty()) {
                    vals.add(tmp);
                    tmp = "";
                }
                for(String val: vals) {
                    ret.addAll(expression(val));
                }
                ret.add(new Token("endArr", "endArr"));
            }
            else {
                m = re.get("float").matcher(s.get(i));
                if(m.find()) {
                    ret.add(new Token("float", m.group()));
                    continue;
                }
                m = re.get("int").matcher(s.get(i));
                if(m.find()) {
                    ret.add(new Token("int", m.group()));
                    continue;
                }
                m = re.get("bool").matcher(s.get(i));
                if(m.find()) {
                    ret.add(new Token("bool", m.group()));
                    continue;
                }
                if(i < s.size() - 2) {
                    if(s.get(i + 1).equals("(")) {
                        ret.add(new Token("funcCall", "funcCall"));
                        ret.add(new Token("id", s.get(i)));
                        i += 2;
                        flag = false;
                        ArrayList<String> args = new ArrayList<String>();
                        tmp = "";
                        if(s.get(i).equals(")")) {
                            ret.add(new Token("endFuncCall", "endFuncCall"));
                        }
                        else {
                            Boolean flag2 = false;
                            while(!s.get(i).equals(")")) {
                                for(int j = 0; j < s.get(i).length(); j++) {
                                    if(s.get(i).charAt(j) == '\"') {
                                        flag = !flag;
                                        tmp += s.get(i).charAt(j);
                                    }
                                    else if(!flag && s.get(i).charAt(j) == '{') {
                                        flag2 = !flag2;
                                        tmp += s.get(i).charAt(j);
                                    }
                                    else if(!flag && s.get(i).charAt(j) == '}') {
                                        flag2 = !flag2;
                                        tmp += s.get(i).charAt(j);
                                    }
                                    else if(!flag && !flag2 && s.get(i).charAt(j) == ',') {
                                        args.add(tmp);
                                        tmp = "";
                                    }
                                    else tmp += s.get(i).charAt(j);
                                }
                                i++;
                                if(flag) {
                                    stop = true;
                                    return ret;
                                }
                            }
                            args.add(tmp);
                            for(String arg: args) {
                                ret.addAll(expression(arg));
                            }
                            ret.add(new Token("endFuncCall", "endFuncCall"));
                        }
                    }
                    else if(!s.get(i).isEmpty()) ret.add(new Token("id", s.get(i).replaceAll("[ \n\t\r\f]*", "")));
                }
                else if(!s.get(i).isEmpty()) ret.add(new Token("id", s.get(i).replaceAll("[ \n\t\r\f]*", "")));
            }
        }
        ret.add(new Token("endExpr", "endExpr"));
        return ret;
    }
}

class Class {
    public ArrayList<Function> methods;
    public ArrayList<Variable> fields;
    public String id;

    Class(String name) {
        methods = new ArrayList<Function>();
        fields = new ArrayList<Variable>();
        id = name;
    }
}

class Obj {
    public String id, type;
    public Class value;

    Obj(String ty, String name, Class val) {
        type = ty;
        id = name;
        value = val;
    }
}

class Function {
    public ArrayList<String> argsId, argsType;
    public ArrayList<Token> stat;
    public String id, retType;

    Function(String name, String ret, ArrayList<String> ids, ArrayList<String> types, ArrayList<Token> s) {
        id = name;
        retType = ret;
        argsId = (ArrayList<String>)ids.clone();
        argsType = (ArrayList<String>)types.clone();
        stat = (ArrayList<Token>)s.clone();
    }
}

class Variable {
    public String id, type, value;

    Variable(String ty, String name, String val) {
        type = ty;
        id = name;
        value = val;
    }

    void assign(String ty, String val) {
        type = ty;
        value = val;
    }

    @Override
    String toString() {
        return id + ": " + type + ": " + value;
    }
}

color white = color(255), black = color(0), blue = color(51, 153, 255), fc = color(255), sc = color(0);
ArrayList<String> s = new ArrayList<String>();
ArrayList<String> varNames = new ArrayList<String>();
ArrayList<String> funcNames = new ArrayList<String>();
ArrayList<String> console = new ArrayList<String>();
HashMap<String, Variable> variables = new HashMap<String, Variable>();
HashMap<String, Function> functions = new HashMap<String, Function>();
// HashMap<String, Class> classes = new HashMap<String, Class>();
// HashMap<String, Obj> objs = new HashMap<String, Obj>();
HashMap<Integer, Boolean> keyFlags = new HashMap<Integer, Boolean>();
int t = 0, keyt = 0, dur = 20, size = 18, block = 0, keyKeep1 = 0, keyKeep2 = 0, start = 0, sw = 1;
float scrollX = 0, scrollY = 0, scrollConsoleY = 0, beforeMouseY = 0, beforeConsoleMouseY = 0, beforeMouseX = 0, w = 100, h = 100, maxW = 0;
boolean keepPressXBar = false, keepPressYBar = false, keepPressConsoleYBar = false, keepPress = false, scrollXFlag = false, isFirst = false, mouseReleasedCanvas = true;
color bg = color(0);
String prevKey = "";
Cursor cursor = new Cursor(), beforeCursor = new Cursor();
Lexer lexer = new Lexer();

void setup() {
    size(1000, 600);
    background(black);
    s.add("");
    scrollX = 0.05 * width;
    scrollY = 0.01 * height;
    scrollConsoleY = 0.75 * height;
    textFont(createFont("Arial", 20));
}

void draw() {
    noStroke();
    fill(black);
    rect(0, 0, 0.4 * width, height);
    textSize(size);
    stroke(0);
    drawCanvas();
    textSize(size);
    strokeWeight(3);
    fill(42, 42, 48);
    noStroke();
    rect(0, 0, 0.4 * width, height);
    drawCursor();
    drawText();
    drawConsole();
    t++;
    if(t > 60) t = 0;
    if(keyPressed) {
        if(prevKey.equals(String.valueOf(key))) {
            if(keyt < dur) keyt++;
            else {
                keyt = dur / 2;
                if(key != CODED) keyTyped();
            }
        }
        else {
            keyt = 0;
            if(key != CODED) keyTyped();
        }
    }
    else {
        keyt = 0;
        prevKey = "";
    }
}

String getStringInRangeOfCursor() {
    String ret = "";
    if(cursor.gt(beforeCursor)) {
        int l = beforeCursor.line, r = beforeCursor.row;
        for(; l <= cursor.line; l++) {
            if(l != cursor.line) {
                ret += s.get(l).substring(r, s.get(l).length()) + "\n";
            }
            else {
                ret += s.get(l).substring(r, cursor.row);
            }
            r = 0;
        }
    }
    if(beforeCursor.gt(cursor)) {
        int l = cursor.line, r = cursor.row;
        for(; l <= beforeCursor.line; l++) {
            if(l != beforeCursor.line) {
                ret += s.get(l).substring(r, s.get(l).length()) + "\n";
            }
            else {
                ret += s.get(l).substring(r, beforeCursor.row);
            }
            r = 0;
        }
    }
    return ret;
}

void keyPressed() {
    if(key == CODED) {
        if(keyCode == LEFT) {
            cursor.prev();
            beforeCursor.prev();
        }
        else if(keyCode == RIGHT) {
            cursor.next();
            beforeCursor.next();
        }
        else if(keyCode == UP) {
            cursor.up();
            beforeCursor.up();
        }
        else if(keyCode == DOWN) {
            cursor.down();
            beforeCursor.down();
        }
        else {
            keyFlags.put(keyCode, true);
        }
    }
}

void keyReleased() {
    if(key == CODED) {
        if(keyFlags.get(keyCode) != null) {
            keyFlags.put(keyCode, false);
        }
    }
    keyPressed = false;
}

void keyTyped() {
    boolean f = cursor.eq(beforeCursor);
    if(!(keyFlags.get(157) != null && keyFlags.get(157) && (key == 'c' || key == 'a')) && cursor.gt(beforeCursor)) {
        while(!cursor.eq(beforeCursor)) {
            if(cursor.row > 0) {
                StringBuilder builder = new StringBuilder(s.get(cursor.line));
                if(cursor.row < s.get(cursor.line).length()) {
                    if(s.get(cursor.line).charAt(cursor.row - 1) == '{' && s.get(cursor.line).charAt(cursor.row) == '}' ||
                    s.get(cursor.line).charAt(cursor.row - 1) == '(' && s.get(cursor.line).charAt(cursor.row) == ')' ||
                    s.get(cursor.line).charAt(cursor.row - 1) == '[' && s.get(cursor.line).charAt(cursor.row) == ']' ||
                    s.get(cursor.line).charAt(cursor.row - 1) == '\"' && s.get(cursor.line).charAt(cursor.row) == '\"'
                    ) {
                        builder.delete(cursor.row - 1, cursor.row + 1);
                        s.set(cursor.line, builder.toString());
                        cursor.prev();
                    }
                    else {
                        builder.delete(cursor.row - 1, cursor.row);
                        s.set(cursor.line, builder.toString());
                        cursor.prev();
                    }
                }
                else if(cursor.row >= 4 && s.get(cursor.line).substring(0, cursor.row).equals(repeat(" ", cursor.row))) {
                    block = cursor.row / 4 * 4;
                    if(cursor.row % 4 != 0) block -= cursor.row % 4;
                    else block -= 4;
                    builder.delete(block, cursor.row);
                    s.set(cursor.line, builder.toString());
                    int rpos = cursor.row;
                    for(int i = 0; i < rpos - block; i++) {
                        cursor.prev();
                    }
                }
                else {
                    builder.delete(cursor.row - 1, cursor.row);
                    s.set(cursor.line, builder.toString());
                    cursor.prev();
                }
            }
            else {
                cursor.prev();
                s.set(cursor.line, s.get(cursor.line) + s.get(cursor.line + 1));
                s.remove(cursor.line + 1);
                if(cursor.row > 0 && s.get(cursor.line).equals(repeat(" ", cursor.row))) block = cursor.row - cursor.row % 4;
            }
        }
    }
    else if(!(keyFlags.get(157) != null && keyFlags.get(157) && key == 'c') && beforeCursor.gt(cursor)) {
        while(!cursor.eq(beforeCursor)) {
            if(beforeCursor.row > 0) {
                StringBuilder builder = new StringBuilder(s.get(beforeCursor.line));
                if(beforeCursor.row < s.get(beforeCursor.line).length()) {
                    if(s.get(beforeCursor.line).charAt(beforeCursor.row - 1) == '{' && s.get(beforeCursor.line).charAt(beforeCursor.row) == '}' ||
                    s.get(beforeCursor.line).charAt(beforeCursor.row - 1) == '(' && s.get(beforeCursor.line).charAt(beforeCursor.row) == ')' ||
                    s.get(beforeCursor.line).charAt(beforeCursor.row - 1) == '[' && s.get(beforeCursor.line).charAt(beforeCursor.row) == ']' ||
                    s.get(beforeCursor.line).charAt(beforeCursor.row - 1) == '\"' && s.get(beforeCursor.line).charAt(beforeCursor.row) == '\"'
                    ) {
                        builder.delete(beforeCursor.row - 1, beforeCursor.row + 1);
                        s.set(beforeCursor.line, builder.toString());
                        beforeCursor.prev();
                    }
                    else {
                        builder.delete(beforeCursor.row - 1, beforeCursor.row);
                        s.set(beforeCursor.line, builder.toString());
                        beforeCursor.prev();
                    }
                }
                else if(beforeCursor.row >= 4 && s.get(beforeCursor.line).substring(0, beforeCursor.row).equals(repeat(" ", beforeCursor.row))) {
                    block = beforeCursor.row / 4 * 4;
                    if(beforeCursor.row % 4 != 0) block -= beforeCursor.row % 4;
                    else block -= 4;
                    builder.delete(block, beforeCursor.row);
                    s.set(beforeCursor.line, builder.toString());
                    int rpos = beforeCursor.row;
                    for(int i = 0; i < rpos - block; i++) {
                        beforeCursor.prev();
                    }
                }
                else {
                    builder.delete(beforeCursor.row - 1, beforeCursor.row);
                    s.set(beforeCursor.line, builder.toString());
                    beforeCursor.prev();
                }
            }
            else {
                beforeCursor.prev();
                s.set(beforeCursor.line, s.get(beforeCursor.line) + s.get(beforeCursor.line + 1));
                s.remove(beforeCursor.line + 1);
                if(beforeCursor.row > 0 && s.get(beforeCursor.line).equals(repeat(" ", beforeCursor.row))) block = beforeCursor.row - beforeCursor.row % 4;
            }
        }
    }
    if(key == TAB) {
        if(s.get(cursor.line).substring(0, cursor.row).equals(repeat(" ", cursor.row))) block += 4;
        StringBuilder builder = new StringBuilder(s.get(cursor.line));
        if(cursor.row % 4 != 0) builder.insert(cursor.row, repeat(" ", cursor.row % 4));
        else builder.insert(cursor.row, repeat(" ", 4));
        s.set(cursor.line, builder.toString());
        if(cursor.row % 4 != 0) {
            int r = cursor.row;
            for(int i = 0; i < r % 4; i++) {
                cursor.next();
                beforeCursor.next();
            }
        }
        else {
            for(int i = 0; i < 4; i++) {
                cursor.next();
                beforeCursor.next();
            }
        }
    }
    else if(key == ' ') {
        StringBuilder builder = new StringBuilder(s.get(cursor.line));
        builder.insert(cursor.row, key);
        s.set(cursor.line, builder.toString());
        cursor.next();
        beforeCursor.next();
        if(cursor.row >= 4 && s.get(cursor.line).substring(0, cursor.row).equals(repeat(" ", cursor.row))) block = cursor.row / 4 * 4;
    }
    else if(key == BACKSPACE) {
        if(cursor.line != 0 || cursor.row != 0) {
            if(f) {
                if(cursor.row > 0) {
                    StringBuilder builder = new StringBuilder(s.get(cursor.line));
                    if(cursor.row < s.get(cursor.line).length()) {
                        if(s.get(cursor.line).charAt(cursor.row - 1) == '{' && s.get(cursor.line).charAt(cursor.row) == '}' ||
                        s.get(cursor.line).charAt(cursor.row - 1) == '(' && s.get(cursor.line).charAt(cursor.row) == ')' ||
                        s.get(cursor.line).charAt(cursor.row - 1) == '[' && s.get(cursor.line).charAt(cursor.row) == ']' ||
                        s.get(cursor.line).charAt(cursor.row - 1) == '\"' && s.get(cursor.line).charAt(cursor.row) == '\"'
                        ) {
                            builder.delete(cursor.row - 1, cursor.row + 1);
                            s.set(cursor.line, builder.toString());
                            cursor.prev();
                            beforeCursor.prev();
                        }
                        else {
                            builder.delete(cursor.row - 1, cursor.row);
                            s.set(cursor.line, builder.toString());
                            cursor.prev();
                            beforeCursor.prev();
                        }
                    }
                    else if(cursor.row >= 4 && s.get(cursor.line).substring(0, cursor.row).equals(repeat(" ", cursor.row))) {
                        block = cursor.row / 4 * 4;
                        if(cursor.row % 4 != 0) block -= cursor.row % 4;
                        else block -= 4;
                        builder.delete(block, cursor.row);
                        s.set(cursor.line, builder.toString());
                        int rpos = cursor.row;
                        for(int i = 0; i < rpos - block; i++) {
                            cursor.prev();
                            beforeCursor.prev();
                        }
                    }
                    else {
                        builder.delete(cursor.row - 1, cursor.row);
                        s.set(cursor.line, builder.toString());
                        cursor.prev();
                        beforeCursor.prev();
                    }
                }
                else {
                    cursor.prev();
                    beforeCursor.prev();
                    s.set(cursor.line, s.get(cursor.line) + s.get(cursor.line + 1));
                    s.remove(cursor.line + 1);
                    if(cursor.row > 0 && s.get(cursor.line).equals(repeat(" ", cursor.row))) block = cursor.row - cursor.row % 4;
                }
            }
        }
    }
    else if(key == ENTER) {
        if(cursor.row == s.get(cursor.line).length()) {
            cursor.enter();
            beforeCursor.enter();
            s.add(cursor.line, repeat(" ", block));
            for(int i = 0; i < block; i++) {
                cursor.next();
                beforeCursor.next();
            }
        }
        else if(cursor.row > 0 && cursor.row <= s.get(cursor.line).length() - 1 && (
            s.get(cursor.line).charAt(cursor.row - 1) == '(' && s.get(cursor.line).charAt(cursor.row) == ')' ||
            s.get(cursor.line).charAt(cursor.row - 1) == '{' && s.get(cursor.line).charAt(cursor.row) == '}' ||
            s.get(cursor.line).charAt(cursor.row - 1) == '[' && s.get(cursor.line).charAt(cursor.row) == ']'
        )) {
            s.add(cursor.line + 1, s.get(cursor.line).substring(cursor.row, s.get(cursor.line).length()));
            s.set(cursor.line, s.get(cursor.line).substring(0, cursor.row));
            cursor.next();
            beforeCursor.next();
            StringBuilder builder = new StringBuilder(s.get(cursor.line));
            block += 4;
            builder.insert(cursor.row, repeat(" ", block));
            s.set(cursor.line, builder.toString());
            for(int i = 0; i < block; i++) {
                cursor.next();
                beforeCursor.next();
            }
            s.add(cursor.line + 1, repeat(" ", block - 4) + s.get(cursor.line).substring(cursor.row, s.get(cursor.line).length()));
            s.set(cursor.line, s.get(cursor.line).substring(0, cursor.row));
        }
        else {
            s.add(cursor.line + 1, s.get(cursor.line).substring(cursor.row, s.get(cursor.line).length()));
            s.set(cursor.line, s.get(cursor.line).substring(0, cursor.row));
            cursor.enter();
            beforeCursor.enter();
        }
        textSize(size);
        fill(black);
        rect(0.4 * width, 0, 0.6 * width, height);
        drawNewCanvas();
    }
    else if(key == '{') {
        StringBuilder builder = new StringBuilder(s.get(cursor.line));
        builder.insert(cursor.row, "{}");
        s.set(cursor.line, builder.toString());
        cursor.next();
        beforeCursor.next();
    }
    else if(key == '}') {
        if(cursor.row < s.get(cursor.line).length() && s.get(cursor.line).charAt(cursor.row) == '}') cursor.next();
        else {
            StringBuilder builder = new StringBuilder(s.get(cursor.line));
            builder.insert(cursor.row, key);
            s.set(cursor.line, builder.toString());
            cursor.next();
            beforeCursor.next();
        }
        textSize(size);
        fill(black);
        rect(0.4 * width, 0, 0.6 * width, height);
        drawNewCanvas();
    }
    else if(key == '[') {
        StringBuilder builder = new StringBuilder(s.get(cursor.line));
        builder.insert(cursor.row, "[]");
        s.set(cursor.line, builder.toString());
        cursor.next();
        beforeCursor.next();
    }
    else if(key == ']') {
        if(cursor.row < s.get(cursor.line).length() && s.get(cursor.line).charAt(cursor.row) == ']') {
            cursor.next();
            beforeCursor.next();
        }
        else {
            StringBuilder builder = new StringBuilder(s.get(cursor.line));
            builder.insert(cursor.row, key);
            s.set(cursor.line, builder.toString());
            cursor.next();
            beforeCursor.next();
        }
    }
    else if(key == '(') {
        StringBuilder builder = new StringBuilder(s.get(cursor.line));
        builder.insert(cursor.row, "()");
        s.set(cursor.line, builder.toString());
        cursor.next();
        beforeCursor.next();
    }
    else if(key == ')') {
        if(cursor.row < s.get(cursor.line).length() && s.get(cursor.line).charAt(cursor.row) == ')') {
            cursor.next();
            beforeCursor.next();
        }
        else {
            StringBuilder builder = new StringBuilder(s.get(cursor.line));
            builder.insert(cursor.row, key);
            s.set(cursor.line, builder.toString());
            cursor.next();
            beforeCursor.next();
        }
    }
    else if(key == '\"') {
        StringBuilder builder = new StringBuilder(s.get(cursor.line));
        builder.insert(cursor.row, "\"\"");
        s.set(cursor.line, builder.toString());
        cursor.next();
        beforeCursor.next();
    }
    else if(keyFlags.get(157) != null && keyFlags.get(157) && key == 'v') {
        String[] texts = pasteFromClipboard().split("[\n\t\r\f]");
        for(int i = 0; i < texts.length; i++) {
            StringBuilder builder = new StringBuilder(s.get(cursor.line));
            builder.insert(cursor.row, texts[i]);
            s.set(cursor.line, builder.toString());
            for(int j = 0; j < texts[i].length(); j++) {
                cursor.next();
                beforeCursor.next();
            }
            if(i != texts.length - 1) {
                if(cursor.row == s.get(cursor.line).length()) {
                    cursor.enter();
                    beforeCursor.enter();
                    s.add(cursor.line, repeat(" ", block));
                    for(int k = 0; k < block; k++) {
                        cursor.next();
                        beforeCursor.next();
                    }
                }
                else if(cursor.row > 0 && cursor.row <= s.get(cursor.line).length() - 1 && (
                    s.get(cursor.line).charAt(cursor.row - 1) == '(' && s.get(cursor.line).charAt(cursor.row) == ')' ||
                    s.get(cursor.line).charAt(cursor.row - 1) == '{' && s.get(cursor.line).charAt(cursor.row) == '}' ||
                    s.get(cursor.line).charAt(cursor.row - 1) == '[' && s.get(cursor.line).charAt(cursor.row) == ']'
                )) {
                    s.add(cursor.line + 1, s.get(cursor.line).substring(cursor.row, s.get(cursor.line).length()));
                    s.set(cursor.line, s.get(cursor.line).substring(0, cursor.row));
                    cursor.next();
                    beforeCursor.next();
                    StringBuilder builder2 = new StringBuilder(s.get(cursor.line));
                    block += 4;
                    builder2.insert(cursor.row, repeat(" ", block));
                    s.set(cursor.line, builder2.toString());
                    for(int k = 0; k < block; k++) {
                        cursor.next();
                        beforeCursor.next();
                    }
                    s.add(cursor.line + 1, s.get(cursor.line).substring(cursor.row, s.get(cursor.line).length()));
                    s.set(cursor.line, s.get(cursor.line).substring(0, cursor.row));
                }
                else {
                    s.add(cursor.line + 1, s.get(cursor.line).substring(cursor.row, s.get(cursor.line).length()));
                    s.set(cursor.line, s.get(cursor.line).substring(0, cursor.row));
                    cursor.enter();
                    beforeCursor.enter();
                }
            }
        }
        textSize(size);
        fill(black);
        rect(0.4 * width, 0, 0.6 * width, height);
        drawNewCanvas();
    }
    else if(keyFlags.get(157) != null && keyFlags.get(157) && key == 'c') {
        String text = getStringInRangeOfCursor();
        copyToClipboard(text);
    }
    else if(keyFlags.get(157) != null && keyFlags.get(157) && key == 'a') {
        beforeCursor.line = 0;
        beforeCursor.row = 0;
        cursor.line = s.size() - 1;
        cursor.row = s.get(s.size() - 1).length();
    }
    else {
        StringBuilder builder = new StringBuilder(s.get(cursor.line));
        builder.insert(cursor.row, key);
        s.set(cursor.line, builder.toString());
        cursor.next();
        beforeCursor.next();
        textSize(size);
        fill(black);
        rect(0.4 * width, 0, 0.6 * width, height);
        drawNewCanvas();
    }

    if(key == ';') {
        textSize(size);
        fill(black);
        rect(0.4 * width, 0, 0.6 * width, height);
        drawNewCanvas();
    }
    t = 0;
    keyt++;
    prevKey = String.valueOf(key);
}

void drawCursor() {
    if(mouseX >= 0 && mouseX <= 0.4 * width) cursor(TEXT);
    else cursor(ARROW);
    if(mousePressed) {
        if(keepPressYBar || mouseX >= 0.38 * width && mouseX <= 0.4 * width && mouseY >= 0 && mouseY <= 0.7 * height && s.size() * textAscent() > 0.7 * height) {
            if(!keepPressYBar) {
                keepPressYBar = true;
                beforeMouseY = mouseY - scrollY;
            }
            else {
                scrollY = mouseY - beforeMouseY;
                if(scrollY < 0.01 * height) scrollY = 0.01 * height;
                else if(scrollY + 0.7 * height * 0.69 * height / ((s.size() + size) * textAscent()) > 0.69 * height) scrollY = 0.69 * height - 0.7 * height * 0.69 * height / ((s.size() + size) * textAscent());
            }
        }
        else if(keepPressXBar || mouseX >= 0 && mouseX <= 0.4 * width && mouseY >= 0.68 * height && mouseY <= 0.7 * height) {
            if(!keepPressXBar) {
                keepPressXBar = true;
                beforeMouseX = mouseX - scrollX;
            }
            else {
                scrollX = mouseX - beforeMouseX;
                if(scrollX < 0.05 * width) scrollX = 0.05 * width;
                else if(scrollX > 0.2 * width) scrollX = 0.2 * width;
            }
        }
        else if(keepPressConsoleYBar || mouseX >= 0.38 * width && mouseX <= 0.4 * width && mouseY >= 0.75 * height && mouseY <= height && (console.size() + 1) * textAscent() > 0.25 * height) {
            if(!keepPressConsoleYBar) {
                keepPressConsoleYBar = true;
                beforeConsoleMouseY = mouseY - scrollConsoleY;
            }
            else {
                scrollConsoleY = mouseY - beforeConsoleMouseY;
                if(scrollConsoleY < 0.75 * height) scrollConsoleY = 0.75 * height;
                else if(scrollConsoleY + 0.2 * height * 0.2 * height / (textAscent() * (console.size() + 1)) > height) scrollConsoleY = height - 0.2 * height * 0.2 * height / (textAscent() * (console.size() + 1));
            }
        }
        else if(mouseX >= 0 && mouseX <= 0.38 * width && mouseY >= 0 && mouseY <= height) {
            int y = int((mouseY - 0.01 * height + (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height)) / textAscent()), x = 0;
            if(y >= s.size()) cursor.set(s.size() - 1, s.get(s.size() - 1).length());
            else if(y < 0) cursor.set(0, 0);
            else {
                x = int((mouseX - 0.1 * width + scrollX) / (textWidth(s.get(y)) / s.get(y).length()));
                if(x >= s.get(y).length()) cursor.set(y, s.get(y).length());
                else if(x < 0) cursor.set(y, 0);
                else cursor.set(y, x + 1);
            }
            if(!keepPress) beforeCursor = new Cursor(cursor.line, cursor.row);
            keepPress = true;
        }
    }
    if(cursor.gt(beforeCursor)) {
        fill(180);
        int l = beforeCursor.line, r = beforeCursor.row;
        for(; l <= cursor.line; l++) {
            if(l != cursor.line) {
                rect(textWidth(s.get(l).substring(0, r)) + (0.1 * width - scrollX), textAscent() * l + 0.01 * height - (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height), textWidth(s.get(l).substring(r, s.get(l).length())), textAscent() + 5);
            }
            else {
                rect(textWidth(s.get(l).substring(0, r)) + (0.1 * width - scrollX), textAscent() * l + 0.01 * height - (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height), textWidth(s.get(l).substring(r, cursor.row)), textAscent() + 5);
            }
            r = 0;
        }
    }
    if(beforeCursor.gt(cursor)) {
        fill(180);
        int l = cursor.line, r = cursor.row;
        for(; l <= beforeCursor.line; l++) {
            if(l != beforeCursor.line) {
                rect(textWidth(s.get(l).substring(0, r)) + (0.1 * width - scrollX), textAscent() * l + 0.01 * height - (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height), textWidth(s.get(l).substring(r, s.get(l).length())), textAscent() + 5);
            }
            else {
                rect(textWidth(s.get(l).substring(0, r)) + (0.1 * width - scrollX), textAscent() * l + 0.01 * height - (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height), textWidth(s.get(l).substring(r, beforeCursor.row)), textAscent() + 5);
            }
            r = 0;
        }
    }
    if(textWidth(s.get(cursor.line).substring(0, cursor.row)) + (0.1 * width - scrollX) < 0.38 * width) {
        stroke((t < 30) ? blue : color(42, 42, 48));
        line(textWidth(s.get(cursor.line).substring(0, cursor.row)) + (0.1 * width - scrollX), cursor.line * textAscent() + 0.02 * height - (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height), textWidth(s.get(cursor.line).substring(0, cursor.row)) + (0.1 * width - scrollX), (cursor.line + 1) * textAscent() + 0.02 * height - (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height));
    }
}

void mouseReleased() {
    if(keepPressYBar) {
        keepPressYBar = false;
        beforeMouseY = mouseY;
    }
    if(keepPressXBar) {
        keepPressXBar = false;
        beforeMouseX = mouseX;
    }
    if(keepPressConsoleYBar) {
        keepPressConsoleYBar = false;
        beforeConsoleMouseY = mouseY;
    }
    if(keepPress) {
        keepPress = false;
    }
    mouseReleasedCanvas = true;
}

void mouseWheel(MouseEvent e) {
    if(mouseX >= 0 && mouseX <= 0.4 * width) {
        scrollY += textAscent() * e.getCount();
        if(scrollY < 0.01 * height) scrollY = 0.01 * height;
        else if(scrollY + 0.7 * height * 0.69 * height / ((s.size() + size) * textAscent()) > 0.69 * height) scrollY = 0.69 * height - 0.7 * height * 0.69 * height / ((s.size() + size) * textAscent());
    }
}

void drawConsole() {
    noStroke();
    fill(21, 21, 24);
    rect(0, 0.7 * height, 0.4 * width, 0.05 * height);
    fill(0);
    rect(0, 0.75 * height, 0.4 * width, 0.25 * height);
    fill(white);
    textAlign(LEFT, CENTER);
    for(int line = 0; line < console.size(); line++) {
        if(textAscent() * line + 0.8 * height + (0.75 * height - scrollConsoleY) * (textAscent() * console.size()) / (0.2 * height) > 0.76 * height) text(console.get(line), 0.01 * width, textAscent() * line + 0.8 * height + (0.75 * height - scrollConsoleY) * (textAscent() * console.size()) / (0.2 * height));
    }
    if(console.size() * textAscent() > 0.2 * height) {
        fill(63, 63, 72);
        rect(0.38 * width, scrollConsoleY, 0.02 * width, 0.2 * height * 0.2 * height / (textAscent() * (console.size() + 1)));
    }
}

void drawText() {
    fill(white);
    textAlign(LEFT, CENTER);
    scrollXFlag = false;
    maxW = 0;
    for(int line = 0; line < s.size(); line++) {
        if(textWidth(s.get(line)) > 0.33 * width) scrollXFlag = true;
        if(maxW < textWidth(s.get(line))) maxW = textWidth(s.get(line));
        text(s.get(line), 0.1 * width - scrollX, textAscent() * line + 0.01 * height - (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height), 0.28 * width + scrollX, textAscent() + 5);
    }
    textAlign(RIGHT, CENTER);
    noStroke();
    fill(42, 42, 48);
    rect(0, 0, 0.04 * width, 0.7 * height);
    fill(white);
    for(int line = 0; line < s.size(); line++) {
        text(line + 1, 0.03 * width, textAscent() * (line + 1) - (scrollY - 0.01 * height) * ((s.size() + size) * textAscent()) / (0.69 * height));
    }
    textAlign(LEFT, CENTER);
    noStroke();
    fill(42, 42, 48);
    rect(0.38 * width, 0, 0.02 * width, height);
    if(s.size() * textAscent() > 0.69 * height) {
        fill(63, 63, 72);
        rect(0.38 * width, scrollY, 0.02 * width, 0.7 * height * 0.69 * height / ((s.size() + size) * textAscent()));
    }
    fill(42, 42, 48);
    rect(0, 0.68 * height, 0.4 * width, 0.02 * height);
    if(scrollXFlag) {
        fill(63, 63, 72);
        rect(scrollX - 0.05 * width, 0.68 * height, 0.2 * width, 0.02 * height);
    }
}

// -10 + 50 * (2 + (5 + 1) * 2) - 10 / 3
// sub, int, add, int, mul, lp, int, add, lp, int, add, int, rp, mul, int, rp, sub, int, div, int
void intCalc(ArrayList<Token> expr, String loc) {
    int lval = 0, rval = 0;
    // *, /, %の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("mul")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = (int)parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = (int)parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = (int)parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("int", String.valueOf(lval * rval)));
            j -= 2;
        }
        else if(expr.get(j).kind.equals("div")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = (int)parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = (int)parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = (int)parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("int", String.valueOf(lval / rval)));
            j -= 2;
        }
        else if(expr.get(j).kind.equals("mod")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = (int)parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = (int)parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = (int)parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("int", String.valueOf(lval % rval)));
            j -= 2;
        }
    }
    // +, -の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("add")) {
            if(j == 0) lval = 0;
            else if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = (int)parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = (int)parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = (int)parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            if(j == 0) {
                expr.remove(0);
                expr.set(0, new Token("int", String.valueOf(lval - rval)));
            }
            else {
                expr.subList(j - 1, j + 1).clear();
                expr.set(j - 1, new Token("int", String.valueOf(lval - rval)));
            }
            expr.set(j - 1, new Token("int", String.valueOf(lval + rval)));
            if(j == 0) j--;
            else j -= 2;
        }
        else if(expr.get(j).kind.equals("sub")) {
            if(j == 0) lval = 0;
            else if(j == expr.size() - 1) {
                return;
            }
            else if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = (int)parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = (int)parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = (int)parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            if(j == 0) {
                expr.remove(0);
                expr.set(0, new Token("int", String.valueOf(lval - rval)));
            }
            else {
                expr.subList(j - 1, j + 1).clear();
                expr.set(j - 1, new Token("int", String.valueOf(lval - rval)));
            }
            if(j == 0) j--;
            else j -= 2;
        }
    }
    if(expr.get(0).kind.equals("id")) {
        expr.set(0, new Token("int", variables.get(loc + "$" + expr.get(0).value).value));
    }
}

void floatCalc(ArrayList<Token> expr, String loc) {
    float lval = 0, rval = 0;
    // *, /, %の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("mul")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("float", String.valueOf(lval * rval)));
            j -= 2;
        }
        else if(expr.get(j).kind.equals("div")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("float", String.valueOf(lval / rval)));
            j -= 2;
        }
        else if(expr.get(j).kind.equals("mod")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("float", String.valueOf(lval % rval)));
            j -= 2;
        }
    }
    // +, -の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("add")) {
            if(j == 0) lval = 0;
            else if(j == expr.size() - 1) {
                return;
            }
            else if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            if(j == 0) {
                expr.remove(0);
                expr.set(0, new Token("int", String.valueOf(lval - rval)));
            }
            else {
                expr.subList(j - 1, j + 1).clear();
                expr.set(j - 1, new Token("int", String.valueOf(lval - rval)));
            }
            expr.set(j - 1, new Token("float", String.valueOf(lval + rval)));
            if(j == 0) j--;
            else j -= 2;
        }
        else if(expr.get(j).kind.equals("sub")) {
            if(j == 0) lval = 0;
            else if(j == expr.size() - 1) {
                return;
            }
            else if(expr.get(j - 1).kind.equals("int")) lval = parseInt(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("float")) lval = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lval = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int")) rval = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("float")) rval = (int)parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rval = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            if(j == 0) {
                expr.remove(0);
                expr.set(0, new Token("int", String.valueOf(lval - rval)));
            }
            else {
                expr.subList(j - 1, j + 1).clear();
                expr.set(j - 1, new Token("int", String.valueOf(lval - rval)));
            }
            expr.set(j - 1, new Token("float", String.valueOf(lval - rval)));
            if(j == 0) j--;
            else j -= 2;
        }
    }
    if(expr.get(0).kind.equals("id")) {
        expr.set(0, new Token("float", variables.get(loc + "$" + expr.get(0).value).value));
    }
}

void boolCalc(ArrayList<Token> expr, String loc) {
    boolean lval = false, rval = false;
    float lnum = 0, rnum = 0;
    String lstr = "", rstr = "";
    // <. <=, >, >=の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("lt")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int") || expr.get(j - 1).kind.equals("float")) lnum = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lnum = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lnum = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int") || expr.get(j + 1).kind.equals("float")) rnum = parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rnum = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rnum = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("bool", String.valueOf(lnum < rnum)));
            j -= 2;
        }
        else if(expr.get(j).kind.equals("lte")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int") || expr.get(j - 1).kind.equals("float")) lnum = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lnum = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lnum = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int") || expr.get(j + 1).kind.equals("float")) rnum = parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rnum = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rnum = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("bool", String.valueOf(lnum <= rnum)));
            j -= 2;
        }
        else if(expr.get(j).kind.equals("gt")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int") || expr.get(j - 1).kind.equals("float")) lnum = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lnum = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lnum = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int") || expr.get(j + 1).kind.equals("float")) rnum = parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rnum = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rnum = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("bool", String.valueOf(lnum > rnum)));
            j -= 2;
        }
        else if(expr.get(j).kind.equals("gte")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int") || expr.get(j - 1).kind.equals("float")) lnum = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lnum = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lnum = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                }
            }
            if(expr.get(j + 1).kind.equals("int") || expr.get(j + 1).kind.equals("float")) rnum = parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rnum = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rnum = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("bool", String.valueOf(lnum >= rnum)));
            j -= 2;
        }
    }
    // ==, !=の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("eq")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int") || expr.get(j - 1).kind.equals("float")) lnum = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lnum = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lnum = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("bool")) lstr = variables.get(loc + "$" + expr.get(j - 1).value).value;
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("string")) lstr = variables.get(loc + "$" + expr.get(j - 1).value).value;
                }
            }
            if(expr.get(j + 1).kind.equals("int") || expr.get(j + 1).kind.equals("float")) rnum = parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rnum = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rnum = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("bool")) rstr = variables.get(loc + "$" + expr.get(j + 1).value).value;
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("string")) rstr = variables.get(loc + "$" + expr.get(j + 1).value).value;
                }
            }
            expr.subList(j - 1, j + 1).clear();
            if(!lstr.isEmpty() || !rstr.isEmpty()) expr.set(j - 1, new Token("bool", String.valueOf(lstr.equals(rnum))));
            else expr.set(j - 1, new Token("bool", String.valueOf(lnum == rnum)));
            lstr = "";
            rstr = "";
            j -= 2;
        }
        else if(expr.get(j).kind.equals("neq")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("int") || expr.get(j - 1).kind.equals("float")) lnum = parseFloat(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) lnum = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) lnum = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("bool")) lstr = variables.get(loc + "$" + expr.get(j - 1).value).value;
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("string")) lstr = variables.get(loc + "$" + expr.get(j - 1).value).value;
                }
            }
            if(expr.get(j + 1).kind.equals("int") || expr.get(j + 1).kind.equals("float")) rnum = parseFloat(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) rnum = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) rnum = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value);
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("bool")) rstr = variables.get(loc + "$" + expr.get(j + 1).value).value;
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("string")) rstr = variables.get(loc + "$" + expr.get(j + 1).value).value;
                }
            }
            expr.subList(j - 1, j + 1).clear();
            if(!lstr.isEmpty() || !rstr.isEmpty()) expr.set(j - 1, new Token("bool", String.valueOf(lstr.equals(rnum))));
            else expr.set(j - 1, new Token("bool", String.valueOf(lnum == rnum)));
            lstr = "";
            rstr = "";
            j -= 2;
        }
    }
    // &&の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("and")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("bool")) lval = parseBoolean(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id") && variables.get(loc + "$" + expr.get(j - 1).value) != null) lval = parseBoolean(variables.get(loc + "$" + expr.get(j - 1).value).value);
            if(expr.get(j + 1).kind.equals("bool")) rval = parseBoolean(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id") && variables.get(loc + "$" + expr.get(j + 1).value) != null) rval = parseBoolean(variables.get(loc + "$" + expr.get(j + 1).value).value);
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("bool", String.valueOf(lval && rval)));
            j -= 2;
        }
    }
    // ||の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("or")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("bool")) lval = parseBoolean(expr.get(j - 1).value);
            else if(expr.get(j - 1).kind.equals("id") && variables.get(loc + "$" + expr.get(j - 1).value) != null) lval = parseBoolean(variables.get(loc + "$" + expr.get(j - 1).value).value);
            if(expr.get(j + 1).kind.equals("bool")) rval = parseBoolean(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id") && variables.get(loc + "$" + expr.get(j + 1).value) != null) rval = parseBoolean(variables.get(loc + "$" + expr.get(j + 1).value).value);
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("bool", String.valueOf(lval || rval)));
            if(j == 0) j--;
            else j -= 2;
        }
    }
    if(expr.get(0).kind.equals("id")) {
        expr.set(0, new Token("bool", variables.get(loc + "$" + expr.get(0).value).value));
    }
}

void stringCalc(ArrayList<Token> expr, String loc) {
    String lval = "", rval = "";
    int rnum = 0;
    // *の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("mul")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("string")) lval = expr.get(j - 1).value.replaceAll("\"", "");
            else if(expr.get(j - 1).kind.equals("id") && variables.get(loc + "$" + expr.get(j - 1).value) != null) lval = variables.get(loc + "$" + expr.get(j - 1).value).value;
            if(expr.get(j + 1).kind.equals("int")) rnum = parseInt(expr.get(j + 1).value);
            else if(expr.get(j + 1).kind.equals("id") && variables.get(loc + "$" + expr.get(j + 1).value) != null) rnum = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value);
            expr.subList(j - 1, j + 1).clear();
            String tmp = "";
            for(int k = 0; k < rnum; k++) tmp += lval;
            expr.set(j - 1, new Token("string", String.valueOf(tmp)));
            j -= 2;
        }
    }
    // +の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("add")) {
            if(j == expr.size() - 1) {
                return;
            }
            if(expr.get(j - 1).kind.equals("string")) lval = expr.get(j - 1).value.replaceAll("\"", "");
            else if(expr.get(j - 1).kind.equals("int")) lval = expr.get(j - 1).value;
            else if(expr.get(j - 1).kind.equals("float")) lval = expr.get(j - 1).value;
            else if(expr.get(j - 1).kind.equals("bool")) lval = expr.get(j - 1).value;
            else if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    lval = variables.get(loc + "$" + expr.get(j - 1).value).value;
                }
            }
            if(expr.get(j + 1).kind.equals("string")) rval = expr.get(j + 1).value.replaceAll("\"", "");
            else if(expr.get(j + 1).kind.equals("int")) rval = expr.get(j + 1).value;
            else if(expr.get(j + 1).kind.equals("float")) rval = expr.get(j + 1).value;
            else if(expr.get(j + 1).kind.equals("bool")) rval = expr.get(j + 1).value;
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    rval = variables.get(loc + "$" + expr.get(j + 1).value).value;
                }
            }
            expr.subList(j - 1, j + 1).clear();
            expr.set(j - 1, new Token("string", String.valueOf(lval + rval)));
            if(j == 0) j--;
            else j -= 2;
        }
    }
    if(expr.get(0).kind.equals("id")) {
        expr.set(0, new Token("string", variables.get(loc + "$" + expr.get(0).value).value));
    }
    if(expr.get(0).kind.equals("string")) {
        expr.set(0, new Token("string", expr.get(0).value.replaceAll("\"", "")));
    }
}

String calc(ArrayList<Token> expr, String loc) {
    String type = "", retType = "";
    int lpn = 0, rpn = 0, lsbn = 0, rsbn = 0, n = 0;
    // 関数の呼び出し
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("funcCall")) {
            if(expr.get(j + 1).value.equals("range")) retType = "int[]";
            else if(expr.get(j + 1).value.equals("typeof")) retType = "string";
            else if(expr.get(j + 1).value.equals("random")) retType = "float";
            else if(expr.get(j + 1).value.equals("int")) retType = "int";
            else if(expr.get(j + 1).value.equals("float")) retType = "float";
            else if(expr.get(j + 1).value.equals("bool")) retType = "bool";
            else if(expr.get(j + 1).value.equals("string")) retType = "string";
            else if(expr.get(j + 1).value.equals("max")) retType = "float";
            else if(expr.get(j + 1).value.equals("min")) retType = "float";
            else if(functions.get(loc + "$" + expr.get(j + 1).value) != null) retType = functions.get(loc + "$" + expr.get(j + 1).value).retType;
            else retType = "void";
            j = funcCall(expr, j, loc);
        }
    }
    if(retType.equals("int[]") || retType.equals("float[]") || retType.equals("bool[]") || retType.equals("string[]") || retType.equals("void")) {
        return retType;
    }

    // 配列の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("arr")) {
            ArrayList<Token> ex = new ArrayList<Token>();
            String tmp = "{", ty = "";
            n = j;
            j++;
            while(j < expr.size() && expr.get(j).kind.equals("expr")) {
                j++;
                ArrayList<Token> e = new ArrayList<Token>();
                int exprNum = 0;
                while(exprNum > 0 || !expr.get(j).kind.equals("endExpr")) {
                    if(expr.get(j).kind.equals("expr")) exprNum++;
                    if(expr.get(j).kind.equals("endExpr")) exprNum--;
                    e.add(expr.get(j));
                    j++;
                }
                ty = calc(e, loc);
                if(ty.equals("string")) type = ty;
                else if(ty.equals("bool") && !type.equals("string")) type = ty;
                else if(ty.equals("float") && !type.equals("string") && !type.equals("bool")) type = ty;
                else if(ty.equals("int") && !type.equals("string") && !type.equals("bool") && !type.equals("float")) type = ty;
                else if(ty.equals("string[]")) type = ty;
                else if(ty.equals("bool[]") && !type.equals("string[]")) type = ty;
                else if(ty.equals("float[]") && !type.equals("string[]") && !type.equals("bool[]")) type = ty;
                else if(ty.equals("int[]") && !type.equals("string[]") && !type.equals("bool[]") && !type.equals("float[]")) type = ty;
                ex.add(e.get(0));
                j++;
            }
            for(int i = 0; i < ex.size(); i++) {
                tmp += ex.get(i).value;
                if(i != ex.size() - 1) tmp += ",";
            }
            tmp += "}";
            expr.subList(n, j - 1).clear();
            expr.set(n, new Token(type + "Arr", tmp));
        }
    }
    if(!type.isEmpty()) {
        return type + "[]";
    }

    n = 0;

    float lval = 0, rval = 0;
    // ++, --の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("inc")) {
            if(j > 0 && expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) {
                        lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value) + 1;
                        variables.get(loc + "$" + expr.get(j - 1).value).assign("int", String.valueOf((int)lval));
                    }
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) {
                        lval = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value) + 1;
                        variables.get(loc + "$" + expr.get(j - 1).value).assign("float", String.valueOf(lval));
                    }
                    expr.remove(j);
                    j--;
                }
            }
            else if(j < expr.size() - 1 && expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) {
                        rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value) + 1;
                        variables.get(loc + "$" + expr.get(j + 1).value).assign("int", String.valueOf((int)rval));
                    }
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) {
                        rval = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value) + 1;
                        variables.get(loc + "$" + expr.get(j + 1).value).assign("float", String.valueOf(rval));
                    }
                    expr.remove(j);
                    j--;
                }
            }
        }
        else if(expr.get(j).kind.equals("dec")) {
            if(expr.get(j - 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int")) {
                        lval = parseInt(variables.get(loc + "$" + expr.get(j - 1).value).value) + 1;
                        variables.get(loc + "$" + expr.get(j - 1).value).assign("int", String.valueOf((int)lval));
                    }
                    if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float")) {
                        lval = parseFloat(variables.get(loc + "$" + expr.get(j - 1).value).value) + 1;
                        variables.get(loc + "$" + expr.get(j - 1).value).assign("float", String.valueOf(lval));
                    }
                    expr.remove(j);
                    j--;
                }
            }
            else if(expr.get(j + 1).kind.equals("id")) {
                if(variables.get(loc + "$" + expr.get(j + 1).value) != null) {
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("int")) {
                        rval = parseInt(variables.get(loc + "$" + expr.get(j + 1).value).value) - 1;
                        variables.get(loc + "$" + expr.get(j + 1).value).assign("int", String.valueOf((int)rval));
                    }
                    if(variables.get(loc + "$" + expr.get(j + 1).value).type.equals("float")) {
                        rval = parseFloat(variables.get(loc + "$" + expr.get(j + 1).value).value) - 1;
                        variables.get(loc + "$" + expr.get(j + 1).value).assign("float", String.valueOf(rval));
                    }
                    expr.remove(j);
                    j--;
                }
            }
        }
    }


    // []の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("lsb")) lsbn++;
    }
    // a[1][1]
    if(lsbn > 0) {
        for(int j = 0; j < expr.size(); j++) {
            if(expr.get(j).kind.equals("lsb")) {
                ArrayList<Token> bracket = new ArrayList<Token>();
                lsbn = 0;
                j++;
                int begin = j;
                while(lsbn > 0 || !expr.get(j).kind.equals("rsb")) {
                    if(expr.get(j).kind.equals("lsb")) lsbn++;
                    if(expr.get(j).kind.equals("rsb")) lsbn--;
                    bracket.add(expr.get(j));
                    j++;
                }
                calc(bracket, loc);
                if(j - begin == 1) expr.set(begin, bracket.get(0));
                else {
                    expr.subList(begin, j - 1).clear();
                    expr.set(begin, bracket.get(0));
                }
                j = begin;
            }
        }
    }
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("lsb")) {
            n = parseInt(expr.get(j + 1).value);
            if(expr.get(j - 1).value.equals("int")) {
                ArrayList<Integer> ns = new ArrayList<Integer>();
                do {
                    n = parseInt(expr.get(j + 1).value);
                    ns.add(n);
                    expr.subList(j, j + 3).clear();
                } while(j < expr.size() && expr.get(j).kind.equals("lsb"));
                String tmp = "", part = "0";
                for(int i = ns.size() - 1; i >= 0; i--) {
                    tmp = "{";
                    for(int k = ns.get(i); k > 0; k--) {
                        tmp += part;
                        if(k != 1) tmp += ",";
                    }
                    tmp += "}";
                    part = tmp;
                }
                expr.set(j - 1, new Token("int" + repeat("[]", ns.size()), part));
                return "int" + repeat("[]", ns.size());
            }
            if(expr.get(j - 1).value.equals("float")) {
                ArrayList<Integer> ns = new ArrayList<Integer>();
                do {
                    n = parseInt(expr.get(j + 1).value);
                    ns.add(n);
                    expr.subList(j, j + 3).clear();
                } while(j < expr.size() && expr.get(j).kind.equals("lsb"));
                String tmp = "", part = "0.0";
                for(int i = ns.size() - 1; i >= 0; i--) {
                    tmp = "{";
                    for(int k = ns.get(i); k > 0; k--) {
                        tmp += part;
                        if(k != 1) tmp += ",";
                    }
                    tmp += "}";
                    part = tmp;
                }
                expr.set(j - 1, new Token("float" + repeat("[]", ns.size()), part));
                return "float" + repeat("[]", ns.size());
            }
            if(expr.get(j - 1).value.equals("bool")) {
                ArrayList<Integer> ns = new ArrayList<Integer>();
                do {
                    n = parseInt(expr.get(j + 1).value);
                    ns.add(n);
                    expr.subList(j, j + 3).clear();
                } while(j < expr.size() && expr.get(j).kind.equals("lsb"));
                String tmp = "", part = "false";
                for(int i = ns.size() - 1; i >= 0; i--) {
                    tmp = "{";
                    for(int k = ns.get(i); k > 0; k--) {
                        tmp += part;
                        if(k != 1) tmp += ",";
                    }
                    tmp += "}";
                    part = tmp;
                }
                expr.set(j - 1, new Token("bool" + repeat("[]", ns.size()), part));
                return "bool" + repeat("[]", ns.size());
            }
            if(expr.get(j - 1).value.equals("string")) {
                ArrayList<Integer> ns = new ArrayList<Integer>();
                do {
                    n = parseInt(expr.get(j + 1).value);
                    ns.add(n);
                    expr.subList(j, j + 3).clear();
                } while(j < expr.size() && expr.get(j).kind.equals("lsb"));
                String tmp = "", part = "0";
                for(int i = ns.size() - 1; i >= 0; i--) {
                    tmp = "{";
                    for(int k = ns.get(i); k > 0; k--) {
                        tmp += part;
                        if(k != 1) tmp += ",";
                    }
                    tmp += "}";
                    part = tmp;
                }
                expr.set(j - 1, new Token("string" + repeat("[]", ns.size()), part));
                return "string" + repeat("[]", ns.size());
            }
            if(variables.get(loc + "$" + expr.get(j - 1).value) != null) {
                if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int[]")) {
                    String[] arr = variables.get(loc + "$" + expr.get(j - 1).value).value.replaceAll("^\\{", "").replaceAll("\\}$", "").split(",");
                    if(arr.length <= n) {
                        console.add("");
                        return "";
                    }
                    int val = parseInt(arr[n]);
                    expr.subList(j - 1, j + 2).clear();
                    expr.set(j - 1, new Token("int", String.valueOf(val)));
                    j--;
                }
                else if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float[]")) {
                    String[] arr = variables.get(loc + "$" + expr.get(j - 1).value).value.replaceAll("^\\{", "").replaceAll("\\}$", "").split(",");
                    if(arr.length <= n) {
                        console.add("");
                        return "";
                    }
                    float val = parseFloat(arr[n]);
                    expr.subList(j - 1, j + 2).clear();
                    expr.set(j - 1, new Token("float", String.valueOf(val)));
                    j--;
                }
                else if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("bool[]")) {
                    String[] arr = variables.get(loc + "$" + expr.get(j - 1).value).value.replaceAll("^\\{", "").replaceAll("\\}$", "").split(",");
                    if(arr.length <= n) {
                        console.add("");
                        return "";
                    }
                    Boolean val = parseBoolean(arr[n]);
                    expr.subList(j - 1, j + 2).clear();
                    expr.set(j - 1, new Token("bool", String.valueOf(val)));
                    j--;
                }
                else if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("string[]")) {
                    String[] arr = variables.get(loc + "$" + expr.get(j - 1).value).value.replaceAll("^\\{", "").replaceAll("\\}$", "").split(",");
                    if(arr.length <= n) {
                        console.add("");
                        return "";
                    }
                    String val = arr[n];
                    expr.subList(j - 1, j + 2).clear();
                    expr.set(j - 1, new Token("string", val));
                    j--;
                }
                else if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("int[][]")) {
                    String values = variables.get(loc + "$" + expr.get(j - 1).value).value;
                    ArrayList<String> contents = new ArrayList<String>();
                    int f = 0;
                    String tmp = "";
                    for(int i = 1; i < values.length() - 1; i++) {
                        if(values.charAt(i) == '{') f++;
                        if(values.charAt(i) == '}') f--;
                        if(f == 0 && values.charAt(i) == ',') {
                            contents.add(tmp);
                            tmp = "";
                        }
                        else tmp += values.charAt(i);
                    }
                    if(!tmp.isEmpty()) {
                        contents.add(tmp);
                    }
                    if(contents.size() <= n) {
                        console.add("");
                        return "";
                    }
                    expr.subList(j - 1, j + 2).clear();
                    expr.set(j - 1, new Token("int[]", contents.get(n)));
                    j--;
                }
                else if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("float[][]")) {
                    String values = variables.get(loc + "$" + expr.get(j - 1).value).value;
                    ArrayList<String> contents = new ArrayList<String>();
                    int f = 0;
                    String tmp = "";
                    for(int i = 1; i < values.length() - 1; i++) {
                        if(values.charAt(i) == '{') f++;
                        if(values.charAt(i) == '}') f--;
                        if(f == 0 && values.charAt(i) == ',') {
                            contents.add(tmp);
                            tmp = "";
                        }
                        else tmp += values.charAt(i);
                    }
                    if(!tmp.isEmpty()) {
                        contents.add(tmp);
                    }
                    if(contents.size() <= n) {
                        console.add("");
                        return "";
                    }
                    expr.subList(j - 1, j + 2).clear();
                    expr.set(j - 1, new Token("float[]", contents.get(n)));
                    j--;
                }
                else if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("bool[][]")) {
                    String values = variables.get(loc + "$" + expr.get(j - 1).value).value;
                    ArrayList<String> contents = new ArrayList<String>();
                    int f = 0;
                    String tmp = "";
                    for(int i = 1; i < values.length() - 1; i++) {
                        if(values.charAt(i) == '{') f++;
                        if(values.charAt(i) == '}') f--;
                        if(f == 0 && values.charAt(i) == ',') {
                            contents.add(tmp);
                            tmp = "";
                        }
                        else tmp += values.charAt(i);
                    }
                    if(!tmp.isEmpty()) {
                        contents.add(tmp);
                    }
                    if(contents.size() <= n) {
                        console.add("");
                        return "";
                    }
                    expr.subList(j - 1, j + 2).clear();
                    expr.set(j - 1, new Token("bool[]", contents.get(n)));
                    j--;
                }
                else if(variables.get(loc + "$" + expr.get(j - 1).value).type.equals("string[][]")) {
                    String values = variables.get(loc + "$" + expr.get(j - 1).value).value;
                    ArrayList<String> contents = new ArrayList<String>();
                    int f = 0;
                    String tmp = "";
                    for(int i = 1; i < values.length() - 1; i++) {
                        if(values.charAt(i) == '{') f++;
                        if(values.charAt(i) == '}') f--;
                        if(f == 0 && values.charAt(i) == ',') {
                            contents.add(tmp);
                            tmp = "";
                        }
                        else tmp += values.charAt(i);
                    }
                    if(!tmp.isEmpty()) {
                        contents.add(tmp);
                    }
                    if(contents.size() <= n) {
                        console.add("");
                        return "";
                    }
                    expr.subList(j - 1, j + 2).clear();
                    expr.set(j - 1, new Token("string[]", contents.get(n)));
                    j--;
                }
            }
            else if(expr.get(j - 1).kind.equals("int[]")) {
                String[] arr = expr.get(j - 1).value.replaceAll("^\\{", "").replaceAll("\\}$", "").split(",");
                if(arr.length <= n) {
                    console.add("");
                    return "";
                }
                int val = parseInt(arr[n]);
                expr.subList(j - 1, j + 2).clear();
                expr.set(j - 1, new Token("int", String.valueOf(val)));
                j--;
            }
            else if(expr.get(j - 1).kind.equals("float[]")) {
                String[] arr = expr.get(j - 1).value.replaceAll("^\\{", "").replaceAll("\\}$", "").split(",");
                if(arr.length <= n) {
                    console.add("");
                    return "";
                }
                float val = parseFloat(arr[n]);
                expr.subList(j - 1, j + 2).clear();
                expr.set(j - 1, new Token("float", String.valueOf(val)));
                j--;
            }
            else if(expr.get(j - 1).kind.equals("bool[]")) {
                String[] arr = expr.get(j - 1).value.replaceAll("^\\{", "").replaceAll("\\}$", "").split(",");
                if(arr.length <= n) {
                    console.add("");
                    return "";
                }
                boolean val = parseBoolean(arr[n]);
                expr.subList(j - 1, j + 2).clear();
                expr.set(j - 1, new Token("bool", String.valueOf(val)));
                j--;
            }
            else if(expr.get(j - 1).kind.equals("string[]")) {
                String[] arr = expr.get(j - 1).value.replaceAll("^\\{", "").replaceAll("\\}$", "").split(",");
                if(arr.length <= n) {
                    console.add("");
                    return "";
                }
                String val = arr[n];
                expr.subList(j - 1, j + 2).clear();
                expr.set(j - 1, new Token("string", val));
                j--;
            }
        }
    }
    n = 0;

    // ()の計算
    for(int j = 0; j < expr.size(); j++) {
        if(expr.get(j).kind.equals("lp")) lpn++;
    }
    if(lpn > 0) {
        ArrayList<Token> paren = new ArrayList<Token>();
        boolean flag = false;
        for(int j = 0; j < expr.size(); j++) {
            if(!flag && expr.get(j).kind.equals("lp")) {
                flag = true;
                n++;
            }
            else if(flag && lpn != rpn) {
                if(expr.get(j).kind.equals("rp")) rpn++;
                if(lpn != rpn) {
                    paren.add(expr.get(j));
                    n++;
                }
            }
        }
        if(lpn != rpn) return "";
        calc(paren, loc);
        flag = false;
        for(int j = 0; j < expr.size(); j++) {
            if(!flag && expr.get(j).kind.equals("lp")) {
                flag = true;
                expr.subList(j, j + n).clear();
                expr.set(j, paren.get(0));
            }
        }
    }

    // 単項演算子+, -の計算
    if(expr.get(0).kind.equals("add")) {
        expr.remove(0);
    }
    else if(expr.get(0).kind.equals("sub")) {
        expr.remove(0);
        if(expr.get(0).kind.equals("int")) {
            int val = -parseInt(expr.get(0).value);
            expr.set(0, new Token("int", String.valueOf(val)));
        }
        else if(expr.get(0).kind.equals("float")) {
            float val = -parseFloat(expr.get(0).value);
            expr.set(0, new Token("float", String.valueOf(val)));
        }
        else if(expr.get(0).kind.equals("id")) {
            if(variables.get(loc + "$" + expr.get(0).value) != null) {
                if(variables.get(loc + "$" + expr.get(0).value).type.equals("int")) {
                    int val = -parseInt(variables.get(loc + "$" + expr.get(0).value).value);
                    expr.set(0, new Token("int", String.valueOf(val)));
                }
                else if(variables.get(loc + "$" + expr.get(0).value).type.equals("float")) {
                    float val = -parseFloat(variables.get(loc + "$" + expr.get(0).value).value);
                    expr.set(0, new Token("float", String.valueOf(val)));
                }
                else return "";
            }
        }
        else return "";
    }

    for(int i = 0; i < expr.size(); i++) {
        if(expr.get(i).kind.equals("id")) {
            if(variables.get(loc + "$" + expr.get(i).value) != null) {
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("string[][]")) {
                    type = "string[][]";
                    expr.set(i, new Token("string[][]", variables.get(loc + "$" + expr.get(i).value).value));
                }
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("bool[][]")) {
                    type = "bool[][]";
                    expr.set(i, new Token("bool[][]", variables.get(loc + "$" + expr.get(i).value).value));
                }
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("float[][]")) {
                    type = "float[][]";
                    expr.set(i, new Token("float[][]", variables.get(loc + "$" + expr.get(i).value).value));
                }
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("int[][]")) {
                    type = "int[][]";
                    expr.set(i, new Token("int[][]", variables.get(loc + "$" + expr.get(i).value).value));
                }
                
            }
        }
    }
    if(type.equals("int[][]") || type.equals("float[][]") || type.equals("bool[][]") || type.equals("string[][]")) {
        return type;
    }

    for(int i = 0; i < expr.size(); i++) {
        if(expr.get(i).kind.equals("id")) {
            if(variables.get(loc + "$" + expr.get(i).value) != null) {
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("string[]")) {
                    type = "string[]";
                    expr.set(i, new Token("string[]", variables.get(loc + "$" + expr.get(i).value).value));
                }
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("bool[]")) {
                    type = "bool[]";
                    expr.set(i, new Token("bool[]", variables.get(loc + "$" + expr.get(i).value).value));
                }
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("float[]")) {
                    type = "float[]";
                    expr.set(i, new Token("float[]", variables.get(loc + "$" + expr.get(i).value).value));
                }
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("int[]")) {
                    type = "int[]";
                    expr.set(i, new Token("int[]", variables.get(loc + "$" + expr.get(i).value).value));
                }
                
            }
        }
    }
    if(type.equals("int[]") || type.equals("float[]") || type.equals("bool[]") || type.equals("string[]")) {
        return type;
    }
    for(int i = 0; i < expr.size(); i++) {
        if(
            expr.get(i).kind.equals("lt") ||
            expr.get(i).kind.equals("lte") ||
            expr.get(i).kind.equals("gt") ||
            expr.get(i).kind.equals("gte") ||
            expr.get(i).kind.equals("eq") ||
            expr.get(i).kind.equals("neq")
        ) {
            type = "bool";
            break;
        }
    }
    if(type.equals("bool")) {
        boolCalc(expr, loc);
        return type;
    }
    for(int i = 0; i < expr.size(); i++) {
        if(expr.get(i).kind.equals("string")) {
            type = "string";
            break;
        }
        if(expr.get(i).kind.equals("id")) {
            if(variables.get(loc + "$" + expr.get(i).value) != null) {
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("string")) {
                    type = "string";
                    break;
                }
            }
        }
    }
    if(type.equals("string")) {
        stringCalc(expr, loc);
        return type;
    }
    for(int i = 0; i < expr.size(); i++) {
        if(expr.get(i).kind.equals("bool")) {
            type = "bool";
            break;
        }
        if(expr.get(i).kind.equals("id")) {
            if(variables.get(loc + "$" + expr.get(i).value) != null) {
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("bool")) {
                    type = "bool";
                    break;
                }
            }
        }
    }
    if(type.equals("bool")) {
        boolCalc(expr, loc);
        return type;
    }
    for(int i = 0; i < expr.size(); i++) {
        if(expr.get(i).kind.equals("float")) {
            type = "float";
            break;
        }
        if(expr.get(i).kind.equals("id")) {
            if(variables.get(loc + "$" + expr.get(i).value) != null) {
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("float")) {
                    type = "float";
                    break;
                }
            }
        }
    }
    if(type.equals("float")) {
        floatCalc(expr, loc);
        return type;
    }
    for(int i = 0; i < expr.size(); i++) {
        if(expr.get(i).kind.equals("int")) {
            type = "int";
            break;
        }
        if(expr.get(i).kind.equals("id")) {
            if(variables.get(loc + "$" + expr.get(i).value) != null) {
                if(variables.get(loc + "$" + expr.get(i).value).type.equals("int")) {
                    type = "int";
                    break;
                }
            }
        }
    }
    if(type.equals("int")) {
        intCalc(expr, loc);
        return type;
    }
    return "null";
}

int funcCall(ArrayList<Token> res, int i, String loc) {
    int begin = i;
    i++;
    String id = res.get(i).value;
    i++;
    ArrayList<Token> args = new ArrayList<Token>();
    String type = "";
    while(!res.get(i).kind.equals("endFuncCall")) {
        if(res.get(i).kind.equals("expr")) {
            ArrayList<Token> expr = new ArrayList<Token>();
            i++;
            int exprNum = 0;
            while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                if(res.get(i).kind.equals("expr")) exprNum++;
                if(res.get(i).kind.equals("endExpr")) exprNum--;
                expr.add(res.get(i));
                i++;
            }
            type = calc(expr, loc);
            args.add(expr.get(0));
        }
        i++;
    }
    res.subList(begin, i).clear();
    // if(classes.get(loc + "$" + id) != null) {
    //     Class c = new Class(id);
    //     Function fn = functions.get(loc + "$" + id);
    //     if(args.size() == fn.argsId.size()) {
    //         Pattern scope = Pattern.compile("^" + loc.replaceAll("\\$", "\\\\\\$") + "\\$[^\\$]+$");
    //         ArrayList<String> newVars = new ArrayList<String>();
    //         ArrayList<String> newFuncs = new ArrayList<String>();
    //         ArrayList<String> newClasses = new ArrayList<String>();
    //         Matcher m;
    //         HashMap<String, Variable> vars = (HashMap<String, Variable>)variables.clone();
    //         for(String name: vars.keySet()) {
    //             m = scope.matcher(name);
    //             if(m.find()) {
    //                 String[] tmp = m.group().split("\\$");
    //                 variables.put(loc + "$" + fn.id + "$" + tmp[tmp.length - 1], variables.get(name));
    //                 newVars.add(loc + "$" + fn.id + "$" + tmp[tmp.length - 1]);
    //             }
    //         }
    //         type = "function";
    //         HashMap<String, Function> funcs = (HashMap<String, Function>)functions.clone();
    //         for(String name: funcs.keySet()) {
    //             m = scope.matcher(name);
    //             if(m.find()) {
    //                 String[] tmp = m.group().split("\\$");
    //                 functions.put(loc + "$" + fn.id + "$" + tmp[tmp.length - 1], functions.get(name));
    //                 newFuncs.add(loc + "$" + fn.id + "$" + tmp[tmp.length - 1]);
    //             }
    //         }
    //         HashMap<String, Class> obj = (HashMap<String, Class>)classes.clone();
    //         for(String name: obj.keySet()) {
    //             m = scope.matcher(name);
    //             if(m.find()) {
    //                 String[] tmp = m.group().split("\\$");
    //                 classes.put(loc + "$" + fn.id + "$" + tmp[tmp.length - 1], classes.get(name));
    //                 newClasses.add(loc + "$" + fn.id + "$" + tmp[tmp.length - 1]);
    //             }
    //         }
    //         for(i = 0; i < args.size(); i++) {
    //             variables.put(loc + "$" + fn.id + "$" + fn.argsId.get(i), new Variable(fn.argsType.get(i), fn.argsId.get(i), args.get(i).value));
    //         }
    //         for(i = 0; i < c.fields.size(); i++) {
    //             variables.put(loc + "$" + fn.id + "$" + c.fields.get(i).id, c.fields.get(i));
    //         }
    //         ArrayList<Token> stat = (ArrayList<Token>)fn.stat.clone();
    //         // res.set(begin, new Token(fn.retType, statement(stat, loc + "$" + fn.id)));
    //         statement(stat, loc + "$" + fn.id);
    //         for(i = 0; i < c.fields.size(); i++) {
    //             c.fields.set(i, variables.get(loc + "$" + fn.id + "$" + c.fields.get(i).id));
    //         }
    //         objs.add(loc + "$" + id, new Obj(type, id, c));
    //         for(i = 0; i < args.size(); i++) {
    //             variables.remove(loc + "$" + fn.id + "$" + fn.argsId.get(i));
    //         }
    //         for(String name: newVars) {
    //             variables.remove(name);
    //         }
    //         for(String name: newFuncs) {
    //             functions.remove(name);
    //         }
    //         for(String name: newClasses) {
    //             classes.remove(name);
    //         }
    //         return begin - 1;
    //     }
    // }
    if(functions.get(loc + "$" + id) != null) {
        Function fn = functions.get(loc + "$" + id);
        if(args.size() == fn.argsId.size()) {
            Pattern scope = Pattern.compile("^" + loc.replaceAll("\\$", "\\\\\\$") + "\\$[^\\$]+$");
            ArrayList<String> newVars = new ArrayList<String>();
            ArrayList<String> newFuncs = new ArrayList<String>();
            // ArrayList<String> newClasses = new ArrayList<String>();
            Matcher m;
            HashMap<String, Variable> vars = (HashMap<String, Variable>)variables.clone();
            for(String name: vars.keySet()) {
                m = scope.matcher(name);
                if(m.find()) {
                    String[] tmp = m.group().split("\\$");
                    variables.put(loc + "$" + fn.id + "$" + tmp[tmp.length - 1], variables.get(name));
                    newVars.add(loc + "$" + fn.id + "$" + tmp[tmp.length - 1]);
                }
            }
            type = "function";
            HashMap<String, Function> funcs = (HashMap<String, Function>)functions.clone();
            for(String name: funcs.keySet()) {
                m = scope.matcher(name);
                if(m.find()) {
                    String[] tmp = m.group().split("\\$");
                    functions.put(loc + "$" + fn.id + "$" + tmp[tmp.length - 1], functions.get(name));
                    newFuncs.add(loc + "$" + fn.id + "$" + tmp[tmp.length - 1]);
                }
            }
            // HashMap<String, Class> obj = (HashMap<String, Class>)classes.clone();
            // for(String name: obj.keySet()) {
            //     m = scope.matcher(name);
            //     if(m.find()) {
            //         String[] tmp = m.group().split("\\$");
            //         classes.put(loc + "$" + fn.id + "$" + tmp[tmp.length - 1], classes.get(name));
            //         newClasses.add(loc + "$" + fn.id + "$" + tmp[tmp.length - 1]);
            //     }
            // }
            for(i = 0; i < args.size(); i++) {
                variables.put(loc + "$" + fn.id + "$" + fn.argsId.get(i), new Variable(fn.argsType.get(i), fn.argsId.get(i), args.get(i).value));
            }
            ArrayList<Token> stat = (ArrayList<Token>)fn.stat.clone();
            res.set(begin, new Token(fn.retType, statement(stat, loc + "$" + fn.id)));
            for(i = 0; i < args.size(); i++) {
                variables.remove(loc + "$" + fn.id + "$" + fn.argsId.get(i));
            }
            for(String name: newVars) {
                variables.remove(name);
            }
            for(String name: newFuncs) {
                functions.remove(name);
            }
            // for(String name: newClasses) {
            //     classes.remove(name);
            // }
            return begin - 1;
        }
    }
    if(id.equals("int")) {
        if(args.size() == 1) {
            res.set(begin, new Token("int", String.valueOf(parseInt(args.get(0).value))));
            return begin - 1;
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("float")) {
        if(args.size() == 1) {
            res.set(begin, new Token("float", String.valueOf(parseFloat(args.get(0).value))));
            return begin - 1;
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("bool")) {
        if(args.size() == 1) {
            res.set(begin, new Token("bool", String.valueOf(parseBoolean(args.get(0).value))));
            return begin - 1;
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("string")) {
        if(args.size() == 1) {
            res.set(begin, new Token("string", args.get(0).value));
            return begin - 1;
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("max")) {
        if(args.size() >= 2) {
            boolean f = false;
            for(int j = 0; j < args.size(); j++) {
                if(args.get(j).kind.equals("float")) {
                    f = true;
                    break;
                }
            }
            if(f) {
                float max = -1e9;
                for(int j = 0; j < args.size(); j++) {
                    if(max < parseFloat(args.get(j).value)) max = parseFloat(args.get(j).value);
                }
                res.set(begin, new Token("float", String.valueOf(max)));
                return begin - 1;
            }
            else {
                int max = -(int)1e9;
                for(int j = 0; j < args.size(); j++) {
                    if(max < parseInt(args.get(j).value)) max = parseInt(args.get(j).value);
                }
                res.set(begin, new Token("int", String.valueOf(max)));
                return begin - 1;
            }
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("min")) {
        if(args.size() >= 2) {
            boolean f = false;
            for(int j = 0; j < args.size(); j++) {
                if(args.get(j).kind.equals("float")) {
                    f = true;
                    break;
                }
            }
            if(f) {
                float min = 1e9;
                for(int j = 0; j < args.size(); j++) {
                    if(min > parseFloat(args.get(j).value)) min = parseFloat(args.get(j).value);
                }
                res.set(begin, new Token("float", String.valueOf(min)));
                return begin - 1;
            }
            else {
                int min = (int)1e9;
                for(int j = 0; j < args.size(); j++) {
                    if(min > parseInt(args.get(j).value)) min = parseInt(args.get(j).value);
                }
                res.set(begin, new Token("int", String.valueOf(min)));
                return begin - 1;
            }
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("random")) {
        if(args.size() == 1) {
            float high = parseFloat(args.get(0).value);
            res.set(begin, new Token("float", String.valueOf(random(high))));
            return begin - 1;
        }
        if(args.size() == 2) {
            float low = parseFloat(args.get(0).value), high = parseFloat(args.get(1).value);
            res.set(begin, new Token("float", String.valueOf(random(low, high))));
            return begin - 1;
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("range")) {
        if(args.size() == 1) {
            String val = "{";
            int arg = parseInt(args.get(0).value);
            for(int j = 0; j < arg; j++) {
                val += String.valueOf(j);
                if(j != arg - 1) val += ",";
            }
            val += "}";
            res.set(begin, new Token("int[]", val));
            return begin - 1;
        }
        if(args.size() == 2) {
            String val = "";
            int arg1 = parseInt(args.get(0).value), arg2 = parseInt(args.get(1).value);
            for(int j = arg1; j < arg2; j++) {
                val += String.valueOf(j);
                if(j != arg2 - 1) val += ",";
            }
            val += "}";
            res.set(begin, new Token("int[]", val));
            return begin - 1;
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("typeof")) {
        if(args.size() == 1) {
            res.set(begin, new Token("string", type));
            return begin - 1;
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("println")) {
        String s = "";
        for(Token token: args) {
            if(token.kind.equals("string")) s += token.value;
            else if(token.kind.equals("int") || token.kind.equals("float") || token.kind.equals("bool")) s += token.value;
            else if(token.kind.equals("int[]") ||
                    token.kind.equals("float[]") ||
                    token.kind.equals("bool[]") ||
                    token.kind.equals("string[]") ||
                    token.kind.equals("int[][]") ||
                    token.kind.equals("float[][]") ||
                    token.kind.equals("bool[][]") ||
                    token.kind.equals("string[][]")
            ) {
                s += token.value.replaceAll("\\{", "[").replaceAll("\\}", "]").replaceAll(",", ", ");
            }
            else println(token);
            s += " ";
        }
        console.add(s);
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("print")) {
        String s = "";
        for(Token token: args) {
            if(token.kind.equals("string")) s += token.value;
            else if(token.kind.equals("int") || token.kind.equals("float") || token.kind.equals("bool")) s += String.valueOf(token.value);
            else if(token.kind.equals("int[]") || token.kind.equals("float[]") || token.kind.equals("bool[]") || token.kind.equals("string[]")) {
                s += token.value.replaceAll("^\\{", "[").replaceAll("\\}$", "]").replaceAll(",", ", ");
            }
            s += " ";
        }
        console.set(console.size() - 1, console.get(console.size() - 1) + s);
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("wait")) {
        if(args.size() == 1) {
            int time = parseInt(args.get(0).value);
            int beginTime = millis();
            while(millis() - beginTime < time);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("millis")) {
        if(args.size() == 0) {
            res.set(begin, new Token("int", String.valueOf(millis() - start)));
            return begin - 1;
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("size")) {
        if(args.size() == 2) {
            w = parseFloat(args.get(0).value);
            h = parseFloat(args.get(1).value);
            variables.get(loc + "$width").assign("float", String.valueOf(w));
            variables.get(loc + "$height").assign("float", String.valueOf(h));
            noStroke();
            fill(125);
            if(w >= h) rect(0.4 * width, 0.5 * height - 0.3 * width * h / w, 0.6 * width, 0.6 * width * h / w);
            else rect(0.7 * width - 0.5 * height * w / h, 0, height * w / h, height);
        }
        noFill();
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("background")) {
        if(args.size() == 1) {
            noStroke();
            bg = color(parseFloat(args.get(0).value));
            fill(parseFloat(args.get(0).value));
            if(w >= h) rect(0.4 * width, 0.5 * height - 0.3 * width * h / w, 0.6 * width, 0.6 * width * h / w);
            else rect(0.7 * width - 0.5 * height * w / h, 0, height * w / h, height);
            fill(fc);
            stroke(sc);
        }
        if(args.size() == 3) {
            float r = parseFloat(args.get(0).value), g = parseFloat(args.get(1).value), b = parseFloat(args.get(2).value);
            noStroke();
            bg = color(r, g, b);
            fill(r, g, b);
            if(w >= h) rect(0.4 * width, 0.5 * height - 0.3 * width * h / w, 0.6 * width, 0.6 * width * h / w);
            else rect(0.7 * width - 0.5 * height * w / h, 0, height * w / h, height);
            fill(fc);
            stroke(sc);
        }
        noFill();
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("fill")) {
        if(args.size() == 1) {
            fill(parseFloat(args.get(0).value));
            fc = color(parseFloat(args.get(0).value));
        }
        if(args.size() == 3) {
            float r = parseFloat(args.get(0).value), g = parseFloat(args.get(1).value), b = parseFloat(args.get(2).value);
            fill(r, g, b);
            fc = color(r, g, b);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("stroke")) {
        if(args.size() == 1) {
            stroke(parseFloat(args.get(0).value));
            sc = color(parseFloat(args.get(0).value));
        }
        if(args.size() == 3) {
            float r = parseFloat(args.get(0).value), g = parseFloat(args.get(1).value), b = parseFloat(args.get(2).value);
            stroke(r, g, b);
            sc = color(r, g, b);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("strokeWeight")) {
        if(args.size() == 1) {
            strokeWeight(parseInt(args.get(0).value));
            sw = parseInt(args.get(0).value);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("textSize")) {
        if(args.size() == 1) {
            if(w >= h) textSize(parseFloat(args.get(0).value) * 0.6 * width / w);
            else textSize(parseFloat(args.get(0).value) * height / h);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("text")) {
        if(args.size() == 3) {
            String text = args.get(0).value;
            float x = parseFloat(args.get(1).value), y = parseFloat(args.get(2).value);
            if(w >= h) text(text, 0.4 * width + x * 0.6 * width / w, 0.5 * height - 0.3 * width * h / w + y * 0.6 * width / w);
            else text(text, 0.7 * width - 0.5 * height * w / h + x * height / h, y * height / h);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("textAlign")) {
        if(args.size() == 1) textAlign(parseInt(args.get(0).value));
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("circle")) {
        if(args.size() == 3) {
            float x = parseFloat(args.get(0).value), y = parseFloat(args.get(1).value), d = parseFloat(args.get(2).value);
            if(w >= h) circle(0.4 * width + x * 0.6 * width / w, 0.5 * height - 0.3 * width * h / w + y * 0.6 * width / w, d * 0.6 * width / w);
            else circle(0.7 * width - 0.5 * height * w / h + x * height / h, y * height / h, d * height / h);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("rect")) {
        if(args.size() == 4) {
            float x = parseFloat(args.get(0).value), y = parseFloat(args.get(1).value), wid = parseFloat(args.get(2).value), hei = parseFloat(args.get(3).value);
            if(w >= h) rect(0.4 * width + x * 0.6 * width / w, 0.5 * height - 0.3 * width * h / w + y * 0.6 * width / w, wid * 0.6 * width / w, hei * 0.6 * width / w);
            else rect(0.7 * width - 0.5 * height * w / h + x * height / h, y * height / h, wid * height / h, hei * height / h);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    if(id.equals("ellipse")) {
        if(args.size() == 4) {
            float x = parseFloat(args.get(0).value), y = parseFloat(args.get(1).value), wid = parseFloat(args.get(2).value), hei = parseFloat(args.get(3).value);
            if(w >= h) ellipse(0.4 * width + x * 0.6 * width / w, 0.5 * height - 0.3 * width * h / w + y * 0.6 * width / w, wid * 0.6 * width / w, hei * 0.6 * width / w);
            else ellipse(0.7 * width - 0.5 * height * w / h + x * height / h, y * height / h, wid * height / h, hei * height / h);
        }
        res.set(begin, new Token("void", "void"));
        return begin - 1;
    }
    res.set(begin, new Token("void", "void"));
    return begin - 1;
}

String statement(ArrayList<Token> res, String loc) {
    for(int i = 0; i < res.size(); i++) {
        // if(res.get(i).kind.equals("class")) {
        //     i++;
        //     String id = "";
        //     if(res.get(i).kind.equals("id")) {
        //         id = res.get(i).value;
        //         i++;
        //     }
        //     Class newClass = new Class(id);
        //     if(res.get(i).kind.equals("stat")) {
        //         while(!res.get(i).kind.equals("endStat")) {
        //             if(res.get(i).kind.equals("fn")) {
        //                 i++;
        //                 String fnid = res.get(i).value;
        //                 i++;
        //                 String retType = "";
        //                 if(res.get(i).kind.equals("retType")) {
        //                     retType = res.get(i).value;
        //                     i++;
        //                 }
        //                 ArrayList<String> argsId = new ArrayList<String>();
        //                 ArrayList<String> argsType = new ArrayList<String>();
        //                 ArrayList<Token> stat = new ArrayList<Token>();
        //                 while(!res.get(i).kind.equals("endFn")) {
        //                     if(res.get(i).kind.equals("args")) {
        //                         i++;
        //                         while(!res.get(i).kind.equals("endArgs")) {
        //                             if(res.get(i).kind.equals("id")) {
        //                                 argsId.add(res.get(i).value);
        //                                 i++;
        //                                 if(i < res.size()) argsType.add(res.get(i).value);
        //                                 else return "";
        //                             }
        //                             i++;
        //                         }
        //                     }
        //                     if(res.get(i).kind.equals("stat")) {
        //                         i++;
        //                         int statNum = 0;
        //                         while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
        //                             if(res.get(i).kind.equals("stat")) statNum++;
        //                             if(res.get(i).kind.equals("endStat")) statNum--;
        //                             stat.add(res.get(i));
        //                             i++;
        //                         }
        //                     }
        //                     i++;
        //                 }
        //                 newClass.methods.add(new Function(fnid, retType, argsId, argsType, stat));
        //             }
        //             else if(res.get(i).kind.equals("constructor")) {
        //                 i++;
        //                 String fnid = res.get(i).value;
        //                 i++;
        //                 String retType = id;
        //                 ArrayList<String> argsId = new ArrayList<String>();
        //                 ArrayList<String> argsType = new ArrayList<String>();
        //                 ArrayList<Token> stat = new ArrayList<Token>();
        //                 while(!res.get(i).kind.equals("endConstructor")) {
        //                     if(res.get(i).kind.equals("args")) {
        //                         i++;
        //                         while(!res.get(i).kind.equals("endArgs")) {
        //                             if(res.get(i).kind.equals("id")) {
        //                                 argsId.add(res.get(i).value);
        //                                 i++;
        //                                 if(i < res.size()) argsType.add(res.get(i).value);
        //                                 else return "";
        //                             }
        //                             i++;
        //                         }
        //                     }
        //                     if(res.get(i).kind.equals("stat")) {
        //                         i++;
        //                         int statNum = 0;
        //                         while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
        //                             if(res.get(i).kind.equals("stat")) statNum++;
        //                             if(res.get(i).kind.equals("endStat")) statNum--;
        //                             stat.add(res.get(i));
        //                             i++;
        //                         }
        //                     }
        //                     i++;
        //                 }
        //                 functions.put(loc + "$" + id, new Function(fnid, retType, argsId, argsType, stat));
        //                 funcNames.add(loc + "$" + id);
        //             }
        //             else if(res.get(i).kind.equals("let")) {
        //                 ArrayList<String> vars = new ArrayList<String>();
        //                 ArrayList<String> values = new ArrayList<String>();
        //                 i++;
        //                 String type = "", exprType = "";
        //                 if(res.get(i).kind.equals("type")) {
        //                     type = res.get(i).value;
        //                     i++;
        //                 }
        //                 while(!res.get(i).kind.equals("endLet")) {
        //                     if(res.get(i).kind.equals("id")) {
        //                         vars.add(res.get(i).value);
        //                     }
        //                     else if(res.get(i).kind.equals("expr")) {
        //                         ArrayList<Token> expr = new ArrayList<Token>();
        //                         i++;
        //                         int exprNum = 0;
        //                         while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
        //                             if(res.get(i).kind.equals("expr")) exprNum++;
        //                             if(res.get(i).kind.equals("endExpr")) exprNum--;
        //                             expr.add(res.get(i));
        //                             i++;
        //                         }
        //                         exprType = calc(expr, loc);
        //                         values.add(expr.get(0).value);
        //                     }
        //                     i++;
        //                 }
        //                 int vs = values.size();
        //                 for(int j = 0; j < vars.size(); j++) {
        //                     if(j < vs) {
        //                         if(type.isEmpty()) {
        //                             newClass.fields.add(new Variable(exprType, vars.get(j), values.get(j)));
        //                         }
        //                         else {
        //                             newClass.fields.add(new Variable(type, vars.get(j), values.get(j)));
        //                         }
        //                     }
        //                     else {
        //                         if(type.isEmpty()) {
        //                             newClass.fields.add(new Variable(exprType, vars.get(j), values.get(vs - 1)));
        //                         }
        //                         else {
        //                             newClass.fields.add(new Variable(type, vars.get(j), values.get(vs - 1)));
        //                         }
        //                     }
        //                 }
        //             }
        //         }
        //     }
        //     classes.put(loc + "$" + id, newClass);
        // }
        if(res.get(i).kind.equals("fn")) {
            i++;
            String id = res.get(i).value;
            i++;
            String retType = "";
            if(res.get(i).kind.equals("retType")) {
                retType = res.get(i).value;
                i++;
            }
            ArrayList<String> argsId = new ArrayList<String>();
            ArrayList<String> argsType = new ArrayList<String>();
            ArrayList<Token> stat = new ArrayList<Token>();
            while(!res.get(i).kind.equals("endFn")) {
                if(res.get(i).kind.equals("args")) {
                    i++;
                    while(!res.get(i).kind.equals("endArgs")) {
                        if(res.get(i).kind.equals("id")) {
                            argsId.add(res.get(i).value);
                            i++;
                            if(i < res.size()) argsType.add(res.get(i).value);
                            else return "";
                        }
                        i++;
                    }
                }
                if(res.get(i).kind.equals("stat")) {
                    i++;
                    int statNum = 0;
                    while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                        if(res.get(i).kind.equals("stat")) statNum++;
                        if(res.get(i).kind.equals("endStat")) statNum--;
                        stat.add(res.get(i));
                        i++;
                    }
                }
                i++;
            }
            functions.put(loc + "$" + id, new Function(id, retType, argsId, argsType, stat));
            funcNames.add(loc + "$" + id);
        }
        else if(res.get(i).kind.equals("return")) {
            i++;
            if(i < res.size() && res.get(i).kind.equals("expr")) {
                ArrayList<Token> expr = new ArrayList<Token>();
                i++;
                int exprNum = 0;
                while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                    if(res.get(i).kind.equals("expr")) exprNum++;
                    if(res.get(i).kind.equals("endExpr")) exprNum--;
                    expr.add(res.get(i));
                    i++;
                }
                calc(expr, loc);
                return expr.get(0).value;
            }
            else return "";
        }
        else if(res.get(i).kind.equals("if")) {
            i++;
            boolean flag = false;
            while(!res.get(i).kind.equals("endIf") && !res.get(i).kind.equals("elif") && !res.get(i).kind.equals("else")) {
                if(res.get(i).kind.equals("expr")) {
                    ArrayList<Token> expr = new ArrayList<Token>();
                    i++;
                    int exprNum = 0;
                    while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                        if(res.get(i).kind.equals("expr")) exprNum++;
                        if(res.get(i).kind.equals("endExpr")) exprNum--;
                        expr.add(res.get(i));
                        i++;
                    }
                    calc(expr, loc);
                    if(expr.get(0).value.equals("true")) flag = true;
                }
                i++;
                if(res.get(i).kind.equals("stat")) {
                    i++;
                    int statNum = 0;
                    ArrayList<Token> stat = new ArrayList<Token>();
                    while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                        if(res.get(i).kind.equals("stat")) statNum++;
                        if(res.get(i).kind.equals("endStat")) statNum--;
                        stat.add(res.get(i));
                        i++;
                    }
                    String retVal = "";
                    if(flag) retVal = statement(stat, loc);
                    if(!retVal.isEmpty()) return retVal;
                }
                i++;
            }
            while(!res.get(i).kind.equals("endIf") && !res.get(i).kind.equals("else")) {
                i++;
                if(flag) continue;
                if(res.get(i).kind.equals("expr")) {
                    ArrayList<Token> expr = new ArrayList<Token>();
                    i++;
                    int exprNum = 0;
                    while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                        if(res.get(i).kind.equals("expr")) exprNum++;
                        if(res.get(i).kind.equals("endExpr")) exprNum--;
                        expr.add(res.get(i));
                        i++;
                    }
                    calc(expr, loc);
                    if(expr.get(0).value.equals("true")) flag = true;
                }
                i++;
                if(res.get(i).kind.equals("stat")) {
                    i++;
                    int statNum = 0;
                    ArrayList<Token> stat = new ArrayList<Token>();
                    while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                        if(res.get(i).kind.equals("stat")) statNum++;
                        if(res.get(i).kind.equals("endStat")) statNum--;
                        stat.add(res.get(i));
                        i++;
                    }
                    String retVal = "";
                    if(flag) retVal = statement(stat, loc);
                    if(!retVal.isEmpty()) return retVal;
                }
                i++;
            }
            if(res.get(i).kind.equals("else")) {
                i++;
                if(res.get(i).kind.equals("stat")) {
                    i++;
                    int statNum = 0;
                    ArrayList<Token> stat = new ArrayList<Token>();
                    while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                        if(res.get(i).kind.equals("stat")) statNum++;
                        if(res.get(i).kind.equals("endStat")) statNum--;
                        stat.add(res.get(i));
                        i++;
                    }
                    String retVal = "";
                    if(!flag) retVal = statement(stat, loc);
                    if(!retVal.isEmpty()) return retVal;
                }
            }
        }
        // let i = 0;
        // switch(i) {
        //     case 0:
        //         println(0);
        //     case 1:
        //         println(1);
        //     default:
        //         println(2);
        // }
        // stat: stat,
        //     let: let, id: i, expr: expr, int: 0, endExpr: endExpr, endLet: endLet,
        //     switch: switch, expr: expr, id: i, endExpr: endExpr,
        //         case: case, expr: expr, int: 0, endExpr: endExpr, stat: stat,
        //             funcCall: funcCall, id: println, expr: expr, int: 0, endExpr: endExpr, endFuncCall: endFuncCall,
        //         endStat: endStat
        //         case: case, expr: expr, int: 1, endExpr: endExpr, stat: stat,
        //             funcCall: funcCall, id: println, expr: expr, int: 1, endExpr: endExpr, endFuncCall: endFuncCall,
        //         endStat: endStat,
        //         default: default, stat: stat,
        //             funcCall: funcCall, id: println, expr: expr, int: 2, endExpr: endExpr, endFuncCall: endFuncCall,
        //         endStat: endStat,
        //     endSwitch: endSwitch,
        // endStat: endStat
        else if(res.get(i).kind.equals("switch")) {
            i++;
            ArrayList<Token> expr = new ArrayList<Token>();
            boolean flag = false, fin = false;
            String retVal = "";
            if(res.get(i).kind.equals("expr")) {
                i++;
                int exprNum = 0;
                while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                    if(res.get(i).kind.equals("expr")) exprNum++;
                    if(res.get(i).kind.equals("endExpr")) exprNum--;
                    expr.add(res.get(i));
                    i++;
                }
                calc(expr, loc);
            }
            i++;
            while(res.get(i).kind.equals("case")) {
                i++;
                ArrayList<Token> e = new ArrayList<Token>();
                ArrayList<Token> stat = new ArrayList<Token>();
                if(res.get(i).kind.equals("expr")) {
                    i++;
                    int exprNum = 0;
                    while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                        if(res.get(i).kind.equals("expr")) exprNum++;
                        if(res.get(i).kind.equals("endExpr")) exprNum--;
                        if(!fin) e.add(res.get(i));
                        i++;
                    }
                    if(!fin) calc(e, loc);
                    if(!fin && (expr.get(0).kind.equals("int") || expr.get(0).kind.equals("float")) && (e.get(0).kind.equals("int") || e.get(0).kind.equals("float"))) {
                        float val = parseFloat(expr.get(0).value);
                        float caseVal = parseFloat(e.get(0).value);
                        flag = val == caseVal;
                    }
                    else if(!fin && expr.get(0).kind.equals("bool") && e.get(0).kind.equals("bool")) {
                        boolean val = parseBoolean(expr.get(0).value);
                        boolean caseVal = parseBoolean(e.get(0).value);
                        flag = val == caseVal;
                    }
                    else if(!fin && expr.get(0).kind.equals("string") && e.get(0).kind.equals("string")) {
                        boolean val = parseBoolean(expr.get(0).value);
                        boolean caseVal = parseBoolean(e.get(0).value);
                        flag = val == caseVal;
                    }
                }
                i++;
                if(res.get(i).kind.equals("stat")) {
                    i++;
                    int statNum = 0;
                    while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                        if(res.get(i).kind.equals("stat")) statNum++;
                        if(res.get(i).kind.equals("endStat")) statNum--;
                        if(!fin) stat.add(res.get(i));
                        i++;
                    }
                    i++;
                    if(!fin && flag) {
                        fin = true;
                        retVal = statement(stat, loc);
                    }
                    if(!retVal.isEmpty()) return retVal;
                }
            }
            if(res.get(i).kind.equals("default")) {
                i++;
                ArrayList<Token> stat = new ArrayList<Token>();
                if(res.get(i).kind.equals("stat")) {
                    i++;
                    int statNum = 0;
                    while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                        if(res.get(i).kind.equals("stat")) statNum++;
                        if(res.get(i).kind.equals("endStat")) statNum--;
                        if(!fin) stat.add(res.get(i));
                        i++;
                    }
                    i++;
                    if(!fin) retVal = statement(stat, loc);
                    if(!retVal.isEmpty()) return retVal;
                }
            }
        }
        else if(res.get(i).kind.equals("while")) {
            i++;
            boolean flag;
            ArrayList<Token> expr = new ArrayList<Token>();
            ArrayList<Token> stat = new ArrayList<Token>();
            if(res.get(i).kind.equals("expr")) {
                i++;
                int exprNum = 0;
                while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                    if(res.get(i).kind.equals("expr")) exprNum++;
                    if(res.get(i).kind.equals("endExpr")) exprNum--;
                    expr.add(res.get(i));
                    i++;
                }
            }
            i++;
            if(res.get(i).kind.equals("stat")) {
                i++;
                int statNum = 0;
                while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                    if(res.get(i).kind.equals("stat")) statNum++;
                    if(res.get(i).kind.equals("endStat")) statNum--;
                    stat.add(res.get(i));
                    i++;
                }
            }
            if(stat.size() == 0) return "";
            ArrayList<Token> e, s;
            String retVal = "";
            while(true) {
                e = (ArrayList<Token>)expr.clone();
                s = (ArrayList<Token>)stat.clone();
                calc(e, loc);
                if(e.get(0).value.equals("true")) retVal = statement(s, loc);
                else break;
                if(!retVal.isEmpty()) return retVal;
            }
            i++;
        }
        else if(res.get(i).kind.equals("for")) {
            ArrayList<Token> cond = new ArrayList<Token>();
            ArrayList<Token> update = new ArrayList<Token>();
            ArrayList<Token> stat = new ArrayList<Token>();
            i++;
            if(res.get(i).kind.equals("stat")) {
                i++;
                int statNum = 0;
                while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                    if(res.get(i).kind.equals("stat")) statNum++;
                    if(res.get(i).kind.equals("endStat")) statNum--;
                    if(res.get(i).kind.equals("let")) {
                        ArrayList<String> vars = new ArrayList<String>();
                        ArrayList<String> values = new ArrayList<String>();
                        i++;
                        String type = "", exprType = "";
                        if(res.get(i).kind.equals("type")) {
                            type = res.get(i).value;
                            i++;
                        }
                        while(!res.get(i).kind.equals("endLet")) {
                            if(res.get(i).kind.equals("id")) {
                                vars.add(res.get(i).value);
                                varNames.add(loc + "$" + res.get(i).value);
                            }
                            else if(res.get(i).kind.equals("expr")) {
                                ArrayList<Token> expr = new ArrayList<Token>();
                                i++;
                                int exprNum = 0;
                                while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                                    if(res.get(i).kind.equals("expr")) exprNum++;
                                    if(res.get(i).kind.equals("endExpr")) exprNum--;
                                    expr.add(res.get(i));
                                    i++;
                                }
                                exprType = calc(expr, loc);
                                values.add(expr.get(0).value);
                            }
                            i++;
                        }
                        int vs = values.size();
                        for(int j = 0; j < vars.size(); j++) {
                            if(j < vs) {
                                if(type.isEmpty()) {
                                    variables.put(loc + "$" + vars.get(j), new Variable(exprType, vars.get(j), values.get(j)));
                                }
                                else {
                                    variables.put(loc + "$" + vars.get(j), new Variable(type, vars.get(j), values.get(j)));
                                }
                            }
                            else {
                                if(type.isEmpty()) {
                                    variables.put(loc + "$" + vars.get(j), new Variable(exprType, vars.get(j), values.get(vs - 1)));
                                }
                                else {
                                    variables.put(loc + "$" + vars.get(j), new Variable(type, vars.get(j), values.get(vs - 1)));
                                }
                            }
                        }
                    }
                    i++;
                }
            }
            i++;
            if(res.get(i).kind.equals("expr")) {
                i++;
                int exprNum = 0;
                while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                    if(res.get(i).kind.equals("expr")) exprNum++;
                    if(res.get(i).kind.equals("endExpr")) exprNum--;
                    cond.add(res.get(i));
                    i++;
                }
            }
            i++;
            if(res.get(i).kind.equals("expr")) {
                i++;
                int exprNum = 0;
                while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                    if(res.get(i).kind.equals("expr")) exprNum++;
                    if(res.get(i).kind.equals("endExpr")) exprNum--;
                    update.add(res.get(i));
                    i++;
                }
            }
            i++;
            if(res.get(i).kind.equals("stat")) {
                i++;
                int statNum = 0;
                while(statNum > 0 || !res.get(i).kind.equals("endStat")) {
                    if(res.get(i).kind.equals("stat")) statNum++;
                    if(res.get(i).kind.equals("endStat")) statNum--;
                    stat.add(res.get(i));
                    i++;
                }
            }
            if(stat.size() == 0) return "";
            ArrayList<Token> c, u, s;
            String retVal = "";
            u = (ArrayList<Token>)update.clone();
            while(true) {
                c = (ArrayList<Token>)cond.clone();
                u = (ArrayList<Token>)update.clone();
                s = (ArrayList<Token>)stat.clone();
                calc(c, loc);
                if(c.get(0).value.equals("true")) {
                    retVal = statement(s, loc);
                    calc(u, loc);
                }
                else break;
                if(!retVal.isEmpty()) return retVal;
            }
        }
        else if(res.get(i).kind.equals("let")) {
            ArrayList<String> vars = new ArrayList<String>();
            ArrayList<String> values = new ArrayList<String>();
            i++;
            String type = "", exprType = "";
            if(res.get(i).kind.equals("type")) {
                type = res.get(i).value;
                i++;
            }
            while(!res.get(i).kind.equals("endLet")) {
                if(res.get(i).kind.equals("id")) {
                    vars.add(res.get(i).value);
                    varNames.add(loc + "$" + res.get(i).value);
                }
                else if(res.get(i).kind.equals("expr")) {
                    ArrayList<Token> expr = new ArrayList<Token>();
                    i++;
                    int exprNum = 0;
                    while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                        if(res.get(i).kind.equals("expr")) exprNum++;
                        if(res.get(i).kind.equals("endExpr")) exprNum--;
                        expr.add(res.get(i));
                        i++;
                    }
                    exprType = calc(expr, loc);
                    values.add(expr.get(0).value);
                }
                i++;
            }
            int vs = values.size();
            for(int j = 0; j < vars.size(); j++) {
                if(j < vs) {
                    if(type.isEmpty()) {
                        variables.put(loc + "$" + vars.get(j), new Variable(exprType, vars.get(j), values.get(j)));
                    }
                    else {
                        variables.put(loc + "$" + vars.get(j), new Variable(type, vars.get(j), values.get(j)));
                    }
                }
                else {
                    if(type.isEmpty()) {
                        variables.put(loc + "$" + vars.get(j), new Variable(exprType, vars.get(j), values.get(vs - 1)));
                    }
                    else {
                        variables.put(loc + "$" + vars.get(j), new Variable(type, vars.get(j), values.get(vs - 1)));
                    }
                }
            }
        }
        // [3][2][2]
        // { { { 0, 1 }, { 2, 3 } }, { { 4, 5 }, { 6, 7 } }, { { 8, 9 }, { 10, 11 } } }
        // -> [0][0][0] = 0, [0][0][1] = 1, [0][1][0] = 2, [0][1][1] = 3, [a][b][c] = 4a + 2b + c
        // int[l][m][n] -> [a][b][c] = mna + nb + c
        else if(res.get(i).kind.equals("assign")) {
            ArrayList<String> vars = new ArrayList<String>();
            ArrayList<String> values = new ArrayList<String>();
            ArrayList<Boolean> isArr = new ArrayList<Boolean>();
            boolean flag = false;
            String assignType = "";
            i++;
            while(!res.get(i).kind.equals("endAssign")) {
                if(res.get(i).kind.equals("id")) {
                    vars.add(res.get(i).value);
                    isArr.add(res.get(i).value.contains("["));
                }
                else if(res.get(i).kind.equals("expr")) {
                    ArrayList<Token> expr = new ArrayList<Token>();
                    i++;
                    int exprNum = 0;
                    while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                        if(res.get(i).kind.equals("expr")) exprNum++;
                        if(res.get(i).kind.equals("endExpr")) exprNum--;
                        expr.add(res.get(i));
                        i++;
                    }
                    assignType = calc(expr, loc);
                    values.add(expr.get(0).value);
                }
                i++;
            }
            int vs = values.size();
            for(int j = 0; j < vars.size(); j++) {
                if(j < vs) {
                    if(variables.get(loc + "$" + vars.get(j).split("\\[")[0]) != null) {
                        if(!isArr.get(j)) variables.get(loc + "$" + vars.get(j)).assign(assignType, values.get(j));
                        else {
                            String val = variables.get(loc + "$" + vars.get(j).split("\\[")[0]).value, type = variables.get(loc + "$" + vars.get(j).split("\\[")[0]).type;
                            ArrayList<Integer> ns = new ArrayList<Integer>();
                            ArrayList<String> tmp = new ArrayList<String>();
                            String t = "";
                            int count = 0;
                            for(int k = 0; k < vars.get(j).length(); k++) {
                                if(vars.get(j).charAt(k) == '[') {
                                    if(count == 0) {
                                        if(!t.isEmpty()) tmp.add(t);
                                        t = "";
                                        count++;
                                        continue;
                                    }
                                    count++;
                                }
                                if(vars.get(j).charAt(k) == ']') {
                                    if(count == 1) {
                                        if(!t.isEmpty()) tmp.add(t);
                                        t = "";
                                        count--;
                                        continue;
                                    }
                                    count--;
                                }
                                t += vars.get(j).charAt(k);
                            }
                            if(!t.isEmpty()) tmp.add(t);
                            for(int k = 1; k < tmp.size(); k++) {
                                if(varNames.contains(loc + "$" + tmp.get(k))) ns.add(parseInt(variables.get(loc + "$" + tmp.get(k)).value));
                                else ns.add(parseInt(tmp.get(k)));
                            }
                            ArrayList<Integer> e = new ArrayList<Integer>();
                            ArrayList<Integer> sum = new ArrayList<Integer>();
                            String[] se = en(val).split(",");
                            for(int k = 1; k < se.length - 1; k++) e.add(parseInt(se[k]));
                            sum.add(1);
                            for(int k = 0; k < e.size() - 1; k++) {
                                sum.add(sum.get(k) * e.get(k));
                            }
                            int index = 0;
                            if(ns.size() != sum.size()) {
                                console.add("");
                                return "";
                            }
                            for(int k = 0; k < ns.size(); k++) {
                                index += sum.get(sum.size() - k - 1) * ns.get(k);
                            }
                            String[] tm = val.split("[ \n\t\r\f]*\\{+[ \n\t\r\f]*|[ \n\t\r\f]*\\}+[ \n\t\r\f]*|[ \n\t\r\f]*,[ \n\t\r\f]*");
                            ArrayList<String> vals = new ArrayList<String>();
                            for(int k = 0; k < tm.length; k++) {
                                if(!tm[k].isEmpty()) vals.add(tm[k]);
                            }
                            vals.set(index, values.get(j));
                            int num = 1;
                            for(int k = e.size() - 1; k >= 0; k--) {
                                num *= e.get(k);
                                for(int l = 0; l < vals.size() - num + 1; l += num) {
                                    vals.set(l, "{" + vals.get(l));
                                    vals.set(l + num - 1, vals.get(l + num - 1) + "}");
                                }
                            }
                            String result = "";
                            for(int k = 0; k < vals.size(); k++) {
                                result += vals.get(k);
                                if(k != vals.size() - 1) result += ",";
                            }
                            variables.get(loc + "$" + vars.get(j).split("\\[")[0]).assign(type, result);
                        }
                    }
                    else {
                        console.add("");
                        return "";
                    }
                }
                else {
                    if(variables.get(loc + "$" + vars.get(j).split("\\[")[0]) != null) {
                        if(!isArr.get(j)) variables.get(loc + "$" + vars.get(j)).assign(assignType, values.get(vs - 1));
                        else {
                            String val = variables.get(loc + "$" + vars.get(j).split("\\[")[0]).value, type = variables.get(loc + "$" + vars.get(j).split("\\[")[0]).type;
                            ArrayList<Integer> ns = new ArrayList<Integer>();
                            ArrayList<String> tmp = new ArrayList<String>();
                            String t = "";
                            int count = 0;
                            for(int k = 0; k < vars.get(j).length(); k++) {
                                if(vars.get(j).charAt(k) == '[') {
                                    if(count == 0) {
                                        if(!t.isEmpty()) tmp.add(t);
                                        t = "";
                                        count++;
                                        continue;
                                    }
                                    count++;
                                }
                                if(vars.get(j).charAt(k) == ']') {
                                    if(count == 1) {
                                        if(!t.isEmpty()) tmp.add(t);
                                        t = "";
                                        count--;
                                        continue;
                                    }
                                    count--;
                                }
                                t += vars.get(j).charAt(k);
                            }
                            if(!t.isEmpty()) tmp.add(t);
                            for(int k = 1; k < tmp.size(); k++) {
                                if(varNames.contains(loc + "$" + tmp.get(k))) ns.add(parseInt(variables.get(loc + "$" + tmp.get(k)).value));
                                else ns.add(parseInt(tmp.get(k)));
                            }
                            ArrayList<Integer> e = new ArrayList<Integer>();
                            ArrayList<Integer> sum = new ArrayList<Integer>();
                            String[] se = en(val).split(",");
                            for(int k = 1; k < se.length - 1; k++) e.add(parseInt(se[k]));
                            sum.add(1);
                            for(int k = 0; k < e.size() - 1; k++) {
                                sum.add(sum.get(k) * e.get(k));
                            }
                            int index = 0;
                            if(ns.size() != sum.size()) {
                                console.add("");
                                return "";
                            }
                            for(int k = 0; k < ns.size(); k++) {
                                index += sum.get(sum.size() - k - 1) * ns.get(k);
                            }
                            String[] tm = val.split("[ \n\t\r\f]*\\{+[ \n\t\r\f]*|[ \n\t\r\f]*\\}+[ \n\t\r\f]*|[ \n\t\r\f]*,[ \n\t\r\f]*");
                            ArrayList<String> vals = new ArrayList<String>();
                            for(int k = 0; k < tm.length; k++) {
                                if(!tm[k].isEmpty()) vals.add(tm[k]);
                            }
                            vals.set(index, values.get(vs - 1));
                            int num = 1;
                            for(int k = e.size() - 1; k >= 0; k--) {
                                num *= e.get(k);
                                for(int l = 0; l < vals.size() - num + 1; l += num) {
                                    vals.set(l, "{" + vals.get(l));
                                    vals.set(l + num - 1, vals.get(l + num - 1) + "}");
                                }
                            }
                            String result = "";
                            for(int k = 0; k < vals.size(); k++) {
                                result += vals.get(k);
                                if(k != vals.size() - 1) result += ",";
                            }
                            variables.get(loc + "$" + vars.get(j).split("\\[")[0]).assign(type, result);
                        }
                    }
                    else {
                        console.add("");
                        return "";
                    }
                }
            }
        }
        else if(res.get(i).kind.equals("funcCall")) {
            i = funcCall(res, i, loc);
        }
        else if(res.get(i).kind.equals("expr")) {
            ArrayList<Token> expr = new ArrayList<Token>();
            i++;
            int exprNum = 0;
            while(exprNum > 0 || !res.get(i).kind.equals("endExpr")) {
                if(res.get(i).kind.equals("expr")) exprNum++;
                if(res.get(i).kind.equals("endExpr")) exprNum--;
                expr.add(res.get(i));
                i++;
            }
            calc(expr, loc);
        }
    }
    return "";
}

String en(String val) {
    if(!val.contains(",")) return "1";
    int count = 0;
    ArrayList<String> tmp = new ArrayList<String>();
    String t = "";
    for(int i = 0; i < val.length(); i++) {
        if(val.charAt(i) == '{') {
            if(count != 0) t += val.charAt(i);
            count++;
        }
        else if(val.charAt(i) == '}') {
            if(count != 0) t += val.charAt(i);
            count--;
        }
        else if(val.charAt(i) == ',') {
            if(count == 0) {
                tmp.add(t);
                t = "";
            }
            else t += val.charAt(i);
        }
        else t += val.charAt(i);
    }
    if(!t.isEmpty()) tmp.add(t);
    return tmp.size() + "," + en(tmp.get(0));
}

void bfCompiler(String code) {
    byte[] b = new byte[30000];
    byte[] c = new byte[30000];
    int ptr = 0, n = 0, index = 0, max = 0;
    console = new ArrayList<String>();
    for(int i = 0; i < code.length(); i++) {
        if(code.charAt(i) == '>') {
            ptr++;
            if(ptr > max) max = ptr;
        }
        else if(code.charAt(i) == '<') ptr--;
        else if(code.charAt(i) == '+') b[ptr]++;
        else if(code.charAt(i) == '-') b[ptr]--;
        else if(code.charAt(i) == '.') {
            c[index] = b[ptr];
            index++;
        }
        else if(code.charAt(i) == '[' && b[ptr] == 0) {
            n = 0;
            i++;
            for(; i < code.length(); i++) {
                if(code.charAt(i) == '[') n++;
                if(code.charAt(i) == ']') {
                    if(n > 0) n--;
                    else break;
                }
            }
        }
        else if(code.charAt(i) == ']' && b[ptr] != 0) {
            n = 0;
            i--;
            for(; i >= 0; i--) {
                if(code.charAt(i) == ']') n++;
                if(code.charAt(i) == '[') {
                    if(n > 0) n--;
                    else break;
                }
            }
        }
    }
    byte[] res = new byte[index];
    for(int i = 0; i < index; i++) {
        res[i] = c[i];
    }
    console.add(new String(res));
}

// let a, b: int = 100 + 20 * 5;
// println("Number:", a * 2 + b);
// -> let, type, id, id, expr, int, add, int, mul, int, endExpr, endLet, funcCall, id, expr, string, endExpr, expr, id, mul, int, add, id, endExpr, endFuncCall
void drawNewCanvas() {
    init();
    String str = "";
    boolean bf = false;
    for(String code: s) {
        if(code.equals("// brainfuck")) bf = true;
        if(code.split("//").length > 1) str += code.split("//")[0];
        else str += code;
    }
    if(bf) {
        bfCompiler(str);
        return;
    }
    ArrayList<Token> res = (ArrayList<Token>)lexer.action(str).result.clone();
    if(lexer.stop) {
        return;
    }
    for(String name: varNames) {
        variables.remove(name);
    }
    for(String name: funcNames) {
        functions.remove(name);
    }
    console = new ArrayList<String>();
    start = millis();
    isFirst = true;
    variables.put("main$LEFT", new Variable("int", "LEFT", String.valueOf(LEFT)));
    variables.put("main$RIGHT", new Variable("int", "RIGHT", String.valueOf(RIGHT)));
    variables.put("main$CENTER", new Variable("int", "CENTER", String.valueOf(CENTER)));
    variables.put("main$mouseX", new Variable("int", "mouseX", String.valueOf(int(w * (mouseX - 0.4 * width) / (0.6 * width)))));
    variables.put("main$mouseY", new Variable("int", "mouseY", String.valueOf(int(h * mouseY / height))));
    printArray(res);
    res.remove(res.size() - 1);
    res.remove(0);
    statement(res, "main");
}

void drawCanvas() {
    ArrayList<Token> res = (ArrayList<Token>)lexer.result.clone();
    if(lexer.stop || res.size() < 2) {
        return;
    }
    isFirst = false;
    variables.put("main$mouseX", new Variable("int", "mouseX", String.valueOf(int(w * (mouseX - 0.4 * width) / (0.6 * width)))));
    variables.put("main$mouseY", new Variable("int", "mouseY", String.valueOf(int(h * mouseY / height))));
    // printArray(res);
    // res.remove(res.size() - 1);
    // res.remove(0);
    // statement(res, "main");
    if(funcNames.contains("main$draw")) {
        fill(fc);
        stroke(sc);
        strokeWeight(sw);
        res = new ArrayList<Token>();
        res.add(new Token("funcCall", "funcCall"));
        res.add(new Token("id", "draw"));
        res.add(new Token("endFuncCall", "endFuncCall"));
        funcCall(res, 0, "main");
    }
    if(mousePressed && mouseReleasedCanvas && mouseX >= 0.4 * width && mouseX <= width && mouseY >= 0 && mouseY <= height && funcNames.contains("main$mousePressed")) {
        mouseReleasedCanvas = false;
        res = new ArrayList<Token>();
        res.add(new Token("funcCall", "funcCall"));
        res.add(new Token("id", "mousePressed"));
        res.add(new Token("endFuncCall", "endFuncCall"));
        funcCall(res, 0, "main");
    }
}

void init() {
    strokeWeight(1);
    variables.put("main$width", new Variable("float", "width", "100.0"));
    variables.put("main$height", new Variable("float", "height", "100.0"));
    noFill();
}

String repeat(String str, int n) {
    String ret = "";
    for(int i = 0; i < n; i++) ret += str;
    return ret;
}

void copyToClipboard(String str) {
    Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
    StringSelection ss = new StringSelection(str);
    clipboard.setContents(ss, ss);
}

String pasteFromClipboard() {
    Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
    String str = "";
    try {
        str = (String)clipboard.getContents(null).getTransferData(DataFlavor.stringFlavor);
    } 
    catch(UnsupportedFlavorException e) {
        e.printStackTrace();
        return "";
    } 
    catch (IOException e) {
        e.printStackTrace();
        return "";
    }
    return str;
}