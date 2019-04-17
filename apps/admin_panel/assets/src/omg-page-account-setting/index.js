import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import moment from 'moment'

import Modal from '../omg-modal'
import { Input, Button, Icon, Select } from '../omg-uikit'
import ImageUploaderAvatar from '../omg-uploader/ImageUploaderAvatar'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { getAccountById, updateAccount } from '../omg-account/action'
import { selectGetAccountById } from '../omg-account/selector'
import Copy from '../omg-copy'
import ChooseCategoryStage from '../omg-create-account-modal/ChooseCategoryStage'

const ChooseCategoryContainer = styled.div`
  position: relative;
  text-align: center;
  width: 380px;
  height: 600px;
`
const AccountSettingContainer = styled.div`
  a {
    color: inherit;
    padding-bottom: 5px;
    display: block;
  }
  padding-bottom: 50px;
`
const ProfileSection = styled.div`
  padding-top: 40px;
  input {
    margin-top: 40px;
  }
  button {
    margin-top: 40px;
  }
  form {
    display: flex;
    > div {
      display: inline-block;
    }
    > div:first-child {
      margin-right: 40px;
    }
    > div:nth-child(2) {
      max-width: 300px;
      width: 100%;
    }
  }
`
const Avatar = styled(ImageUploaderAvatar)`
  margin: 0;
`

const CategorySelect = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  button {
    margin-top: 20px;
  }
`

export const NameColumn = styled.div`
  i[name='Copy'] {
    margin-left: 5px;
    cursor: pointer;
    visibility: hidden;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B100};
    }
  }
`

const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({
      currentAccount: selectGetAccountById(state)(props.match.params.accountId)
    }),
    { getAccountById, updateAccount }
  )
)

class AccountSettingPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    getAccountById: PropTypes.func.isRequired,
    updateAccount: PropTypes.func,
    currentAccount: PropTypes.object,
    location: PropTypes.object,
    divider: PropTypes.bool
  }

  constructor (props) {
    super(props)
    this.state = {
      inviteModalOpen: queryString.parse(props.location.search).invite || false,
      name: '',
      description: '',
      avatar: '',
      submitStatus: 'DEFAULT',
      categorySearch: '',
      categorySelect: '',
      categoryTouched: false,
      chooseCategoryModal: false
    }
  }
  componentDidMount () {
    this.setInitialAccountState()
  }
  async setInitialAccountState () {
    const { currentAccount } = this.props;
    if (currentAccount) {
      this.setState({
        name: currentAccount.name,
        description: currentAccount.description,
        avatar: _.get(currentAccount, 'avatar.original'),
        categorySelect: _.get(currentAccount, 'categories.data[0]'),
        categorySearch: _.get(currentAccount, 'categories.data[0].name')
      })
    } else {
      const result = await this.props.getAccountById(this.props.match.params.accountId)
      if (result.data) {
        this.setState({
          name: result.data.name,
          description: result.data.description || '',
          avatar: result.data.avatar.original || '',
          categorySelect: _.get(result, 'data.categories.data[0]') || '',
          categorySearch: _.get(result, 'data.categories.data[0].name') || ''
        })
      }
    }
  }
  onChangeImage = ({ file }) => {
    this.setState({ image: file })
  }
  onChangeName = e => {
    this.setState({ name: e.target.value })
  }
  onChangeDescription = e => {
    this.setState({ description: e.target.value })
  }
  onClickUpdateAccount = async e => {
    e.preventDefault()
    this.setState({ submitStatus: 'SUBMITTING', categoryTouched: false })
    try {
      const result = await this.props.updateAccount({
        accountId: this.props.match.params.accountId,
        name: this.state.name,
        description: this.state.description,
        avatar: this.state.image,
        categoryIds: [_.get(this.state.categorySelect, 'id')]
      })

      if (result.data) {
        this.setState({ submitStatus: 'SUBMITTED' })
      } else {
        this.setState({ submitStatus: 'FAILED' })
      }
    } catch (error) {
      this.setState({ submitStatus: 'FAILED' })
    }
  }

  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'export'}>
        <Icon name='Export' />
        <span>Export</span>
      </Button>
    )
  }
  renderInviteButton = () => {
    return (
      <InviteButton size='small' onClick={this.onClickInviteButton} key={'create'}>
        <Icon name='Plus' /> <span>Invite Member</span>
      </InviteButton>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'updated_at') {
      return moment(data).format()
    }
    if (key === 'username') {
      return data || '-'
    }
    if (key === 'status') {
      return data === 'active' ? 'Active' : 'Pending'
    }
    if (key === 'id') {
      return (
        <NameColumn>
          <span>{data}</span> <Copy data={data} />
        </NameColumn>
      )
    }
    return data
  }
  onChangeCategory = e => {
    this.setState({
      categorySearch: e.target.value,
      categorySelect: '',
      categoryTouched: true,
      chooseCategoryModal: false
    });
  }
  onSelectCategory = category => {
    this.setState({
      categorySearch: category.name,
      categorySelect: category,
      categoryTouched: true,
      chooseCategoryModal: false
    });
  }
  renderCategoriesPicker = ({ data: categories = [] }) => (
    <Select
      placeholder="Category"
      onSelectItem={this.onSelectCategory}
      onChange={this.onChangeCategory}
      value={this.state.categorySearch}
      options={categories.map(category => ({
        key: category.id,
        value: category.name,
        ...category
      }))}
    />
  )
  toggleModal = (e) => {
    e.preventDefault();
    this.setState(oldState => ({ chooseCategoryModal: !oldState.chooseCategoryModal }));
  }
  get shouldSave() {
    const propsCategoryId = _.get(this.props.currentAccount, 'categories.data[0].id')
    const stateCategoryId = _.get(this.state.categorySelect, 'id')
    const sameCategory = propsCategoryId && propsCategoryId === stateCategoryId

    return this.props.currentAccount.name !== this.state.name ||
      this.props.currentAccount.description !== this.state.description ||
      this.state.image ||
      (this.state.categorySelect && !this.state.categorySearch.length) ||
      !sameCategory ||
      this.state.categoryTouched
  }
  renderAccountSettingTab = () => (
    <ProfileSection>
      {this.props.currentAccount && (
        <form onSubmit={this.onClickUpdateAccount} noValidate>
          <Avatar
            onChangeImage={this.onChangeImage}
            size='180px'
            placeholder={this.state.avatar}
          />
          <div>
            <Input
              prefill
              placeholder={'Name'}
              value={this.state.name}
              onChange={this.onChangeName}
            />
            <Input
              placeholder={'Description'}
              value={this.state.description}
              onChange={this.onChangeDescription}
              prefill
            />
            <CategorySelect>
              <div>{this.state.categorySearch}</div>
              <Button
                size='small'
                key={'openModal'}
                onClick={this.toggleModal}
                styleType='secondary'
              >
                <span>{this.state.categorySearch ? 'Edit Category' : 'Add Category'}</span>
              </Button>
            </CategorySelect>
            <Button
              size='small'
              type='submit'
              key={'save'}
              disabled={!this.shouldSave}
              loading={this.state.submitStatus === 'SUBMITTING'}
            >
              <span>Save Changes</span>
            </Button>
          </div>
        </form>
      )}
    </ProfileSection>
  )
  render () {
    return (
      <>
        <Modal
          isOpen={this.state.chooseCategoryModal}
          onRequestClose={this.toggleModal}
          contentLabel='add category modal'
          shouldCloseOnOverlayClick={true}
        >
          <ChooseCategoryContainer>
            <ChooseCategoryStage
              category={this.state.categorySelect}
              onClickBack={this.toggleModal}
              onChooseCategory={this.onSelectCategory}
              goToStage={this.goToStage}
            />
          </ChooseCategoryContainer>
        </Modal>

        <AccountSettingContainer>
          <TopNavigation divider={this.props.divider}
            title='Account Settings'
            secondaryAction={false}
            types={false}
          />
          {this.renderAccountSettingTab()}
        </AccountSettingContainer>
      </>
    )
  }
}
export default enhance(AccountSettingPage)
