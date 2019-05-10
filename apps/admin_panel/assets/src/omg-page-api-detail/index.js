import React, { useState } from 'react'
import PropTypes from 'prop-types'
import { Link, withRouter } from 'react-router-dom'
import styled from 'styled-components'
import moment from 'moment'

import AccessKeyProvider from '../omg-access-key/accessKeyProvider'
import ApiKeyProvider from '../omg-api-keys/apiKeyProvider'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Breadcrumb, Icon, Input, DetailRow, Tag, Button, NavCard, Select, Switch, Id } from '../omg-uikit'

const BreadContainer = styled.div`
  margin-top: 30px;
  color: ${props => props.theme.colors.B100};
  font-size: 14px;
`
const TitleContainer = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  i {
    margin-right: 10px;
    font-size: 1.2rem;
  }
`
const Content = styled.div`
  display: flex;
  flex-direction: row;
`
const DetailSection = styled.div`
  width: 45%;
  margin-right: 10%;
  .copy-icon {
    margin-left: 5px;
    color: ${props => props.theme.colors.B100};
    cursor: pointer;
  }

  .detail-section-header {
    height: 36px;
    margin-bottom: 15px;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
  }

  .button-group {
    margin-top: 30px;
    text-align: right;
  }
`
const AsideSection = styled.div`
  width: 45%;
  .aside-section-header {
    text-align: right;
    margin-bottom: 20px;
  }
  .nav-card {
    margin-bottom: 10px;
  }
`

// eslint-disable-next-line react/prop-types
const EditView = ({ keyType, keyDetail, setView, enableKey, updateKey }) => {
  const derivedLabel = _.get(keyDetail, 'name', '')
  const derivedGlobalRole = _.get(keyDetail, 'global_role', '')
  const derivedStatus = _.get(keyDetail, 'status')

  console.log(keyDetail)

  const [ loading, setLoading ] = useState(false)
  const [ label, setLabel ] = useState(derivedLabel)
  const [ globalRole, setGlobalRole ] = useState(derivedGlobalRole)
  const [ status, setStatus ] = useState(derivedStatus === 'active')

  const handleSave = async () => {
    setLoading(true)
    await updateKey(label)
    await enableKey(status)
    setLoading(false)
    setView('read')
  }

  const hasChanged = () => {
    return label !== derivedLabel ||
      globalRole !== derivedGlobalRole ||
      status !== (derivedStatus === 'active')
  }

  console.log(status)

  return (
    <Content>
      <DetailSection>
        <div className='detail-section-header'>
          <Tag
            icon='Option-Horizontal'
            title='Details'
          />
        </div>
        <DetailRow
          label='Label'
          value={
            <Input
              noBorder
              normalPlaceholder='Label'
              onChange={e => setLabel(e.target.value)}
              value={label}
            />
          }
        />
        {keyType === 'admin' && (
          <DetailRow
            label='Global Role'
            value={
              <Select
                noBorder
                normalPlaceholder='Global Role'
                onSelectItem={role => setGlobalRole(role.key)}
                value={_.startCase(globalRole)}
                options={[
                  { key: 'super_admin', value: 'Super Admin' },
                  { key: 'admin', value: 'Admin' },
                  { key: 'viewer', value: 'Viewer' },
                  { key: 'none', value: 'None' }
                ]}
              />
            }
          />
        )}
        <DetailRow
          label='Status'
          value={
            <>
              <span style={{ marginRight: '10px' }}>
                {status ? 'Active' : 'Inactive'}
              </span>
              <Switch
                open={status}
                onClick={() => setStatus(!status)}
              />
            </>
          }
        />
        <div className='button-group'>
          <Button
            styleType='ghost'
            onClick={() => setView('read')}
            style={{ minWidth: 'initial' }}
          >
            <span>Cancel</span>
          </Button>
          <Button
            styleType='primary'
            onClick={handleSave}
            style={{ minWidth: 'initial', marginLeft: '10px' }}
            disabled={!hasChanged()}
            loading={loading}
          >
            <span>Save</span>
          </Button>
        </div>
      </DetailSection>
    </Content>
  )
}

const ReadView = withRouter(({ keyDetail, keyType, setView, location: { pathname } }) => {
  const id = _.get(keyDetail, 'access_key') || _.get(keyDetail, 'key', '-')
  return (
    <Content>
      <DetailSection>
        <div className='detail-section-header'>
          <Tag
            icon='Option-Horizontal'
            title='Details'
          />
          <Button
            styleType='ghost'
            size='small'
            style={{ minWidth: 'initial' }}
            onClick={() => setView('edit')}
          >
            <span>Edit</span>
          </Button>
        </div>
        <DetailRow
          label='Type'
          value={keyType === 'admin' ? 'Admin Key' : 'Client Key'}
        />
        <DetailRow
          label='ID'
          value={<Id maxChar={200}>{id}</Id>}
        />
        <DetailRow
          label='Label'
          value={<div>{_.get(keyDetail, 'name') || '-'}</div>}
        />
        {keyType === 'admin' && (
          <DetailRow
            label='Global Role'
            value={<div>{_.startCase(_.get(keyDetail, 'global_role')) || '-'}</div>}
          />
        )}
        <DetailRow
          label='Created by'
          value={
            <Id maxChar={20} withCopy={!!_.get(keyDetail, 'creator_user_id')}>
              {_.get(keyDetail, 'creator_user_id') || '-'}
            </Id>
          }
        />
        <DetailRow
          label='Created date'
          icon='Time'
          value={<div>{moment(_.get(keyDetail, 'created_at', '-')).format()}</div>}
        />
        <DetailRow
          label='Status'
          value={<div>{_.get(keyDetail, 'status', '-') === 'active' ? 'Active' : 'Inactive' }</div>}
        />
      </DetailSection>

      <AsideSection>
        <div className='aside-section-header'>
          <Button
            styleType='secondary'
            size='small'
          >
            <Icon name='Plus' style={{ marginRight: '10px' }} />
            <span>Assign This Key</span>
          </Button>
        </div>
        {keyType === 'admin' && (
          <NavCard
            className='nav-card'
            icon='Merchant'
            title='Assigned Accounts'
            subTitle='Lorem ipsum something something else'
            to={`${pathname}/assigned-accounts`}
          />
        )}
      </AsideSection>
    </Content>
  )
})

const ApiKeyDetailPage = ({ match: { params } }) => {
  const { keyType, keyId } = params
  const [ view, setView ] = useState('read')

  // eslint-disable-next-line react/prop-types
  const renderView = ({ keyDetail, updateKey, enableKey }) => {
    const id = _.get(keyDetail, 'access_key') || _.get(keyDetail, 'key', '-')
    return (
      <>
        <BreadContainer>
          <Breadcrumb
            items={[
              <Link key='keys-home' to={`/keys/${keyType}`}>Keys</Link>,
              <Id key='keys-detail' withCopy={false} maxChar={20}>{id}</Id>
            ]}
          />
        </BreadContainer>

        <TopNavigation
          title={
            <TitleContainer>
              <Icon name='Key' />
              <Id withCopy={false} maxChar={20}>{id}</Id>
            </TitleContainer>
          }
          searchBar={false}
          divider={false}
        />

        {view === 'read'
          ? (
            <ReadView
              keyType={keyType}
              keyDetail={keyDetail}
              setView={setView}
            />
          ) : (
            <EditView
              keyType={keyType}
              keyDetail={keyDetail}
              setView={setView}
              updateKey={updateKey}
              enableKey={enableKey}
            />
          )}
      </>
    )
  }

  if (keyType === 'admin') {
    return (
      <AccessKeyProvider
        render={renderView}
        accessKeyId={keyId}
      />
    )
  }

  if (keyType === 'client') {
    return (
      <ApiKeyProvider
        render={renderView}
        apiKeyId={keyId}
      />
    )
  }

  return null
}

ApiKeyDetailPage.propTypes = {
  match: PropTypes.object
}

export default ApiKeyDetailPage
