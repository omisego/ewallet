import React from 'react'
import PropTypes from 'prop-types'

import { Input } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const TransferTo = ({ onRemove }) => {
  return (
    <FilterBox
      key='transfer-to'
      closeClick={onRemove}
    >
      <TagRow
        title='To'
        tooltip='Test tooltip text'
      />

      <Input
        normalPlaceholder='Enter any ID or address'
        // onChange={this.onReEnteredNewPasswordInputChange}
        // value={this.state.reEnteredNewPassword}
      />
    </FilterBox>
  )
}

TransferTo.propTypes = {
  onRemove: PropTypes.func.isRequired
}

export default TransferTo
