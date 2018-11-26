import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon, Avatar } from '../omg-uikit'
import CreateTokenModal from '../omg-create-token-modal'
import ExportModal from '../omg-export-modal'
import ConfigurationsFetcher from '../omg-configuration/configurationFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import { NameColumn } from '../omg-page-account'
import moment from 'moment'
import queryString from 'query-string'
import ExchangePairModal from '../omg-exchange-rate-modal'
import { createSearchTokenQuery } from '../omg-token/searchField'
const TokenDetailPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  > div {
    flex: 1;
  }
  td:first-child {
    width: 50%;
  }
  td:nth-child(2),
  td:nth-child(3) {
    width: 25%;
  }
`
const columns = [
  { key: 'token', title: 'TOKEN NAME', sort: true },
  { key: 'symbol', title: 'SYMBOL', sort: true },
  { key: 'created', title: 'CREATED DATE', sort: true }
]
class TokenDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  state = {
    createTokenModalOpen: queryString.parse(this.props.location.search).createToken || false,
    exportModalOpen: false,
    createExchangePairModalOpen: false
  }

  onClickCreateToken = () => {
    this.setState({ createTokenModalOpen: true })
  }
  onClickCreateExchangePair = () => {
    this.setState({ createExchangePairModalOpen: true })
  }
  onRequestCloseCreateToken = () => {
    this.setState({ createTokenModalOpen: false })
  }
  onRequestCloseCreateExchangePair = () => {
    this.setState({ createExchangePairModalOpen: false })
  }
  onClickExport = () => {
    this.setState({ exportModalOpen: true })
  }
  onRequestCloseExport = () => {
    this.setState({ exportModalOpen: false })
  }

  onClickLoadMore = e => {
    this.setState(({ loadMoreTime }) => ({ loadMoreTime: loadMoreTime + 1 }))
  }

  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'exports'}>
        <Icon name='Export' />
        <span>Export</span>
      </Button>
    )
  }
  renderTransferToken = () => {
    return (
      <Button size='small' styleType='secondary' onClick={this.onClickCreateToken} key={'transfer'}>
        <span>Transfer Token</span>
      </Button>
    )
  }
  renderMintTokenButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateToken} key={'mint'}>
        <Icon name='Plus' /> <span>Create Token</span>
      </Button>
    )
  }
  renderCreateExchangePairButton = () => {
    return (
      <Button
        size='small'
        styleType='secondary'
        onClick={this.onClickCreateExchangePair}
        key={'create pair'}
      >
        <span>Create Exchange Pair</span>
      </Button>
    )
  }
  rowRenderer (key, data, rows) {
    if (key === 'created') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    if (key === 'token') {
      return (
        <NameColumn>
          <Avatar image={rows.avatar} name={rows.symbol} /> <span>{data}</span>
        </NameColumn>
      )
    }
    return data
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/tokens/${data.id}`)
  }
  renderConfigurationPage = ({ data: configurations }) => {
    return (
      <TokenDetailPageContainer>
        <h3>Configuration</h3>
        {configurations.map(config => {
          return (
            <div>{JSON.stringify(config)}</div>
          )
        })}
      </TokenDetailPageContainer>
    )
  }

  render () {
    return (
      <ConfigurationsFetcher
        render={this.renderConfigurationPage}
        {...this.state}
        {...this.props}
        query={{
          page: queryString.parse(this.props.location.search).page
        }}
      />
    )
  }
}

export default withRouter(TokenDetailPage)
