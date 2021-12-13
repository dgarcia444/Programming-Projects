
/* New Grammar to parse
  S  -: E
  E  -: T E2
  E2 -: '|' E3
  E2 -: NIL
  E3 -: T E2
  T  -: F T2
  T2 -: F T2
  T2 -: NIL
  F  -: A F2
  F2 -: '?' F2
  F2 -: NIL
  A  -: C
  A  -: '(' A2
  A2 -: E ')'
 */

/*
//var index = 0

abstract class S {
  //global index to see where we are in the tree
  var index = 0

  //default method to be used by all case classes
  def eval(input: String): Boolean


  def goal(tree: S, input: String): Boolean = {
    val a = tree.eval(input);
    //if we're done consuming strings but there's still stuff in the input
    if (index != input.length) {
      return false
    }
    //return the tree
    return a
  }
}
*/
class RegexEval() {
  //index to keep track of where we are in the tree
  var index = 0

  case class S(left: E) {
    def evalS(input: String): Boolean = {
      val a = left.evalE(input)
      //if we're done consuming strings but there's still stuff in the input
      if (index != input.length) {
        false
      } else a
    }
  }

  abstract class A

  case class E(left: T, right: Option[E2]) {
    // eval left
    // if match you're done
    // else try right path

    // save treeindex
    // try go left path
    // restore treeindex
    // try right path
    def evalE(input: String): Boolean = {
      //save the index
      //used to reset the index when left fails
      val reset = index
      val a1: Boolean = {
        //if we get left, go down left path
        left.evalT(input)
      }
      if (!a1) {
        //reset the index
        index = reset
        right match {
          //if we have a right, go down right path
          case Some(right) => right.evalE2(input)
          case None => false
        }
      } else true
    }
  }


  case class E2(left: E3) {
    def evalE2(input: String): Boolean = left.evalE3(input)
  }

  case class E3(left: T, right: Option[E2]) {
    def evalE3(input: String): Boolean = {
      val reset = index
      val a1: Boolean = {
        //if we get left, go down left path
        left.evalT(input)
      }
      if (!a1) {
        index = reset
        right match {
          //if we have a right, go down right path
          case Some(right) => right.evalE2(input)
          case None => false
        }
      } else true

    }
  }

  case class T(left: F, right: Option[T2]) {
    // try match left
    // if not return false
    // try right
    //fail to match, both return false
    //both need to return true
    def evalT(input: String): Boolean = {
      val a1: Boolean = {
        left.evalF(input)
      }
      // if we've reached the end of the input
      // and there's nothing on the right to concatenate
      if (a1 && right.isEmpty) {
        return true
      }
      right match {
        case Some(right) => a1 && right.evalT2(input)
        case None => false
      }
    }
  }


  case class T2(left: F, right: Option[T2]) {

    def evalT2(input: String): Boolean = {
      val a1: Boolean = {
        left.evalF(input)
      }
      //check for things cases like a in a|b
      if (a1 && right.isEmpty) {
        return true
      }
      right match {
        case Some(right) => a1 && right.evalT2(input)
        case None => false
      }
    }
  }

  case class F(left: A, right: Option[F2]) {

    def evalF(input: String): Boolean = {
      val a1: Boolean = left match {
        case c: C => c.evalC(input)
        case a2: A2 => a2.evalA2(input)
      }
      right match {
        //handle ? case (left?right)
        // right will always return true if there's something there
        case Some(right) => true
        case None => a1
      }
    }
  }

  case class F2(left: Option[F2]) {
    //same thing as above??
    def evalF2(input: String): Boolean = left match {
      case Some(left) => true
      case None => false
    }
  }

  case class C(left: Char) extends A {
    def evalC(input: String): Boolean = {
      // the current character
      //if input matches left, return true, increment index
      //else return false
      //if the current character we have matches with what's on the left
      if (index < input.length && (input.charAt(index) == left || left == '.')) {
        index += 1
        //put new index in string index
        //index = stringindex
        true
      } else {
        false
      }
    }
  }


  case class A2(left: E) extends A {
    def evalA2(input: String): Boolean = left.evalE(input)
  }
}

class RecursiveDescent(input: String) extends RegexEval {
  //index to see where we are in the input string
  var strindex = 0

  def parseS(): S = S(parseE())

  def parseE(): E = E(parseT(), parseE2())

  def parseE2(): Option[E2] = {
    if (strindex < input.length && input(strindex) == '|') {
      strindex += 1; // Advance past |
      Some(E2(parseE3()))
    } else None
  }

  def parseE3(): E3 = E3(parseT(), parseE2())

  def parseT(): T = T(parseF(), parseT2())

  def parseT2(): Option[T2] = {
    /*
    if (strindex < input.length && input(strindex) == ')') {
      strindex += 1
    }
    */
    if (strindex < input.length && (input(strindex).isLetterOrDigit || input(strindex) == '.' || input(strindex) == '(' || input(strindex) == ' ')) {
      Some(T2(parseF(), parseT2()))
    } else None

  }


  def parseF(): F = F(parseA(), parseF2())

  def parseF2(): Option[F2] = {
    if (strindex < input.length && input(strindex) == '?') {
      strindex += 1; // Step over ?
      Some(F2(parseF2()))
    } else None
  }

  def parseA(): A = {
    if (strindex < input.length && input(strindex) == '(') {
      strindex += 1
      val a = parseA2()
      strindex += 1
      a
    }
    else {
      strindex += 1
      C(input(strindex - 1))
    }
  }

  def parseA2(): A2 = A2(parseE())
}


object Main {
  def main(args: Array[String]) {
    val rd = new RecursiveDescent("I (like|love|hate)( (cat|dog))? people")
    val exp2rd = rd.parseS()
    //prints out the tree
    println(exp2rd)
    //take in input
    val a = "I people"
    println("Does " + a + " belong in this pattern? " + exp2rd.evalS(a))
    //val input = scala.io.StdIn.readLine()
    //println("String? " + input)
    //println(exp2rd.eval(input))
  }
}

//((h|j)ell. worl?d)|(42)