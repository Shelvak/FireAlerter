require_relative 'test_helper'

class DevicesConnectionTest < Test::Unit::TestCase
  def test_semaphore_presentation
    results = send_and_receive!(
      '', ">#SEMAFORO[V1.0.0]-(001)<"
    )

    assert_empty ['>$?<', '>SOK<'] - results[:responsed]
  end

  def test_console_presentation_and_lights
    results = send_and_receive!(
      ">#CONSOLA[V1.0.0]-(001)<",
      [62, 67, 80, 67, 1, 0, 1, 1, 1, 60].map(&:chr).join
    )

    assert_empty ['>COK<', '>CPCOK<'] - results[:responsed]
  end
end
