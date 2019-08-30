# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EthElixirOmgAdapter.ResponseBody do
  def transaction_create_success(sender, receiver, amount, currency, fee_amount, fee_currency) do
    data = %{
      "result" => "complete",
      "transactions" => [
        %{
          "fee" => %{
            "amount" => fee_amount,
            "currency" => fee_currency
          },
          "inputs" => [
            %{
              "amount" => 1000,
              "blknum" => 1,
              "currency" => currency,
              "oindex" => 0,
              "owner" => sender,
              "txindex" => 0,
              "utxo_pos" => 1_000_000_000
            }
          ],
          "metadata" => nil,
          "outputs" => [
            %{
              "amount" => amount,
              "currency" => currency,
              "owner" => receiver
            },
            %{
              "amount" => 899,
              "currency" => currency,
              "owner" => sender
            }
          ],
          "sign_hash" => "0x48f63906689205c506877ffe297252dbb0e21b6296671a0fb121b70b8def876a",
          "txbytes" =>
            "0xf8c5d0c3018080c3808080c3808080c3808080f8b2eb94811ae0a85d3f86824da3abe49a2407ea55a8b05294000000000000000000000000000000000000000064ed94811ae0a85d3f86824da3abe49a2407ea55a8b05394000000000000000000000000000000000000000082037feb94000000000000000000000000000000000000000094000000000000000000000000000000000000000080eb94000000000000000000000000000000000000000094000000000000000000000000000000000000000080",
          "typed_data" => %{
            "domain" => %{
              "name" => "OMG Network",
              "salt" => "0xfad5c7f626d80f9256ef01929f3beb96e058b8b4b0e3fe52d84f054c0e2a7a83",
              "verifyingContract" => "0x7d812d4c8017468d8102bd5e64af0d431c77f86a",
              "version" => "1"
            },
            "message" => %{
              "input0" => %{
                "blknum" => 1,
                "oindex" => 0,
                "txindex" => 0
              },
              "input1" => %{
                "blknum" => 0,
                "oindex" => 0,
                "txindex" => 0
              },
              "input2" => %{
                "blknum" => 0,
                "oindex" => 0,
                "txindex" => 0
              },
              "input3" => %{
                "blknum" => 0,
                "oindex" => 0,
                "txindex" => 0
              },
              "metadata" => "0x0000000000000000000000000000000000000000000000000000000000000000",
              "output0" => %{
                "amount" => 100,
                "currency" => currency,
                "owner" => receiver
              },
              "output1" => %{
                "amount" => 895,
                "currency" => currency,
                "owner" => sender
              },
              "output2" => %{
                "amount" => 0,
                "currency" => currency,
                "owner" => currency
              },
              "output3" => %{
                "amount" => 0,
                "currency" => currency,
                "owner" => currency
              }
            },
            "primaryType" => "Transaction",
            "types" => %{
              "EIP712Domain" => [
                %{
                  "name" => "name",
                  "type" => "string"
                },
                %{
                  "name" => "version",
                  "type" => "string"
                },
                %{
                  "name" => "verifyingContract",
                  "type" => "address"
                },
                %{
                  "name" => "salt",
                  "type" => "bytes32"
                }
              ],
              "Input" => [
                %{
                  "name" => "blknum",
                  "type" => "uint256"
                },
                %{
                  "name" => "txindex",
                  "type" => "uint256"
                },
                %{
                  "name" => "oindex",
                  "type" => "uint256"
                }
              ],
              "Output" => [
                %{
                  "name" => "owner",
                  "type" => "address"
                },
                %{
                  "name" => "currency",
                  "type" => "address"
                },
                %{
                  "name" => "amount",
                  "type" => "uint256"
                }
              ],
              "Transaction" => [
                %{
                  "name" => "input0",
                  "type" => "Input"
                },
                %{
                  "name" => "input1",
                  "type" => "Input"
                },
                %{
                  "name" => "input2",
                  "type" => "Input"
                },
                %{
                  "name" => "input3",
                  "type" => "Input"
                },
                %{
                  "name" => "output0",
                  "type" => "Output"
                },
                %{
                  "name" => "output1",
                  "type" => "Output"
                },
                %{
                  "name" => "output2",
                  "type" => "Output"
                },
                %{
                  "name" => "output3",
                  "type" => "Output"
                },
                %{
                  "name" => "metadata",
                  "type" => "bytes32"
                }
              ]
            }
          }
        }
      ]
    }

    success(data)
  end

  def transaction_create_failure do
    failure("transaction.create:insufficient_funds")
  end

  def transaction_submit_typed_success do
    data = %{
      "blknum" => 123_000,
      "txindex" => 111,
      "txhash" => "0xbdf562c24ace032176e27621073df58ce1c6f65de3b5932343b70ba03c72132d"
    }

    success(data)
  end

  def transaction_submit_typed_failure do
    failure("submit:utxo_not_found")
  end

  def post_request_success(data), do: %{"success" => true, "data" => data}

  def post_request_handled_failure(code) do
    %{
      "success" => false,
      "data" => %{"object" => "error", "code" => code}
    }
  end

  def post_request_unhandled_failure, do: %{"something" => "unexpected"}
  def post_request_decoding_failure, do: "invalid"

  defp success(data) do
    %{
      "version" => "1.0",
      "success" => true,
      "data" => data
    }
  end

  defp failure(code) do
    %{
      "version" => "1.0",
      "success" => false,
      "data" => %{
        "code" => code,
        "description" => nil,
        "object" => "error"
      }
    }
  end
end
