require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "opens only the checked routes" do
    user = users(:consulta)
    assert user.pode?("sorders", "index")
    assert user.pode?("customers", "edit"), "edit goes with update"
    assert_not user.pode?("sorders", "destroy")
    assert_not user.pode?("hotels", "index")
  end

  test "acesso total opens everything" do
    assert users(:one).pode?("sistger_imports", "create")
  end

  test "without routes opens nothing" do
    assert_not users(:sem_rotas).pode?("sorders", "index")
  end

  test "keeps only known routes" do
    user = User.create!(email: "novo@example.com", password: "senha123", permissoes: ["", "hotels#index", "inexistente#index"])
    assert_equal ["hotels#index"], user.permissoes
  end
end
