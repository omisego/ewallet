import React from 'react'
import PropTypes from 'prop-types'

import AccountsFetcher from '../../omg-account/accountsFetcher'
import AccountSelect from '../../omg-account-select'
import { Select } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const SelectAccount = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  const onChange = (e) => {
    e.target.value
      ? onUpdate({ [config.key]: e.target.value })
      : clearKey(config.key)
  }

  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <AccountsFetcher
        render={({ data }) => {
          return (
            <Select
              value={values[config.key] || ''}
              onChange={onChange}
              onSelectItem={e => onUpdate({ [config.key]: e.id })}
              normalPlaceholder='Select account'
              type='select'
              options={data.map(account => ({
                key: account.id,
                value: <AccountSelect account={account} />,
                ...account
              }))}
            />
          )
        }}
      />
    </FilterBox>
  )
}

SelectAccount.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object,
  config: PropTypes.object
}

export default SelectAccount
