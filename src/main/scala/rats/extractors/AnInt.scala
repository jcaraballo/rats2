package rats.extractors


object AnInt {
  def unapply(intAsString: String): Option[Int] = try {
    Some(intAsString.toInt)
  } catch {
    case e: NumberFormatException => None
  }
}