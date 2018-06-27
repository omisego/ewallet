import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { withProps, compose } from 'recompose'
import CONSTANT from '../constants'
import { selectCacheQueriesByEntity } from '../omg-cache/selector'
export const createFetcher = (entity, reducer, selectors) => {
  const enhance = compose(
    withProps(props => ({ cacheKey: `${JSON.stringify({ ...props.query, entity })}` })),
    connect(
      (state, props) => {
        return {
          ...selectors(state, props),
          queriesByEntity: selectCacheQueriesByEntity(entity)(state)
        }
      },
      { dispatcher: reducer }
    )
  )
  return enhance(
    class Fetcher extends Component {
      static propTypes = {
        render: PropTypes.func,
        query: PropTypes.shape({
          page: PropTypes.number,
          perPage: PropTypes.number,
          search: PropTypes.string
        }),
        onFetchComplete: PropTypes.func,
        loadingStatus: PropTypes.string,
        cacheKey: PropTypes.string,
        data: PropTypes.array,
        pagination: PropTypes.object,
        queriesByEntity: PropTypes.array
      }
      static defaultProps = {
        onFetchComplete: _.noop
      }
      state = { loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT, data: [] }

      constructor (props) {
        super(props)
        this.fetchDebounce = _.debounce(this.fetch, 300, {
          leading: true,
          trailing: true
        })
      }
      componentDidMount = () => {
        this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.INITIATED })
        this.fetch()
      }
      componentDidUpdate = async nextProps => {
        if (this.props.cacheKey !== nextProps.cacheKey) {
          this.fetched = false
          this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.PENDING })
          await this.fetchDebounce()
        }
      }
      fetchAll = async () => {
        try {
          const promises = this.props.queriesByEntity.map(query => {
            const { page } = JSON.parse(query)
            return this.props.dispatcher({
              ...this.props,
              ...this.props.query,
              page,
              cacheKey: `${JSON.stringify({ ...this.props.query, page, entity })}`
            })
          })
          await Promise.all(promises)
          this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS, data: this.props.data })
        } catch (error) {
          console.log('cannot fetch all cache query with error', error)
        }
      }
      fetch = async () => {
        try {
          this.props.dispatcher({ ...this.props, ...this.props.query }).then(result => {
            this.fetched = true
            if (result.data) {
              this.setState({
                loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS,
                data: this.props.data
              })
              this.props.onFetchComplete()
            } else {
              this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED })
            }
            this.setState({ data: this.props.data })
          })
          setTimeout(() => {
            if (!this.fetched) {
              this.setState({ data: this.props.data })
              console.log('fetching data taking too long... using cached data.')
            }
          }, 3000)
        } catch (error) {
          this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED, data: this.props.data })
        }
      }

      render () {
        return this.props.render({
          ...this.props,
          ...this.props.query,
          individualLoadingStatus: this.state.loadingStatus,
          fetch: this.fetch,
          fetchAll: this.fetchAll,
          data: this.state.data
        })
      }
    }
  )
}
