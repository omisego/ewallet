/* eslint-disable react/prop-types */
import React, { EffectCallback, useEffect } from 'react'
import styled from 'styled-components'
import _ from 'lodash'

import { LoadingSkeleton } from 'omg-uikit'
import ConfigRow from './ConfigRow'

const LoadingSkeletonContainer = styled.div`
  margin-top: 50px;
  > div {
    margin-bottom: 20px;
  }
`
const Grid = styled.div`
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
`

interface BlockchainSettingsProps {
  blockchainEnabled: boolean
  handleCancelClick: EffectCallback
  configurations: { [key: string]: { description: string; key: string } }
  onChangeInput: Function
}

const BlockchainSettings = (props: BlockchainSettingsProps) => {
  const {
    blockchainEnabled,
    handleCancelClick,
    configurations,
    onChangeInput
  } = props

  useEffect(() => {
    return handleCancelClick
  }, [handleCancelClick])

  const isPositiveInteger = (value: string | number): boolean => {
    const numericValue = Number(value)
    return numericValue > 0 && _.isInteger(numericValue)
  }

  const errorMsg = (key: string): string => {
    return `${key} should be a positive integer.`
  }

  interface displaySettings {
    [key: string]: {
      displayName: string
      disableUpdate: boolean
      inputValidator?: (...args: any) => boolean
    }
  }

  const settings: displaySettings = {
    blockchain_json_rpc_url: {
      displayName: 'Blockchain JSON-RPC URL',
      disableUpdate: true
    },
    blockchain_chain_id: {
      displayName: 'Blockchain Chain ID',
      disableUpdate: true
    },
    blockchain_confirmations_threshold: {
      displayName: 'Blockchain Confirmations Threshold',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_deposit_pooling_interval: {
      displayName: 'Blockchain Deposit Polling Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_transaction_poll_interval: {
      displayName: 'Blockchain Transaction Poll Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_state_save_interval: {
      displayName: 'Blockchain State Save Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_sync_interval: {
      displayName: 'Blockchain Sync Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    blockchain_poll_interval: {
      displayName: 'Blockchain Poll Interval',
      disableUpdate: false,
      inputValidator: isPositiveInteger
    },
    omisego_childchain_url: {
      disableUpdate: true,
      displayName: 'OMG Network Child Chain URL'
    },
    omisego_erc20_vault_address: {
      disableUpdate: true,
      displayName: 'OMG Network ERC20 Vault Address'
    },
    omisego_eth_vault_address: {
      disableUpdate: true,
      displayName: 'OMG Network ETH Vault Address'
    },
    omisego_plasma_framework_address: {
      disableUpdate: true,
      displayName: 'OMG Network Plasma Framework Address'
    },
    omisego_watcher_url: {
      disableUpdate: true,
      displayName: 'OMG Network Information Service URL'
    }
  }

  const renderBlockchainSettings = () => {
    const sortedConfigurationList = _.sortBy(
      _.values(_.pick(configurations, _.keys(settings))),
      'position'
    )

    return (
      <>
        <h4>Blockchain Settings</h4>
        {blockchainEnabled ? (
          <Grid>
            {sortedConfigurationList.map((item, index) => {
              const { key, description } = item
              const { disableUpdate, displayName } = settings[key]
              const camelCaseKey = _.camelCase(item.key)
              return (
                <ConfigRow
                  key={index}
                  type="input"
                  description={description}
                  disabled={disableUpdate}
                  inputErrorMessage={disableUpdate ? null : errorMsg(key)}
                  inputValidator={settings[key].inputValidator}
                  name={displayName}
                  onChange={disableUpdate ? null : onChangeInput(camelCaseKey)}
                  value={props[camelCaseKey]}
                />
              )
            })}
          </Grid>
        ) : (
          <div> Blockchain is not enabled. </div>
        )}
      </>
    )
  }

  return (
    <>
      {!_.isEmpty(props.configurations) ? (
        <form>{renderBlockchainSettings()}</form>
      ) : (
        <LoadingSkeletonContainer>
          <LoadingSkeleton width={'150px'} />
          <LoadingSkeleton />
          <LoadingSkeleton />
          <LoadingSkeleton />
        </LoadingSkeletonContainer>
      )}
    </>
  )
}

export default BlockchainSettings
