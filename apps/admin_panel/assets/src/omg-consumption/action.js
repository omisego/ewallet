import * as consumptionService from '../services/consumptionService'

export const getConsumptions = ({ page, perPage, search, cacheKey }) => async dispatch => {
  dispatch({ type: 'CONSUMPTIONS/REQUEST/INITIATED' })
  try {
    const result = await consumptionService.getConsumptions({
      perPage: perPage,
      page,
      sort: { by: 'created_at', dir: 'desc' },
      search_term: search
    })
    if (result.data.success) {
      return dispatch({
        type: 'CONSUMPTIONS/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({ type: 'CONSUMPTIONS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'CONSUMPTIONS/REQUEST/FAILED', error })
  }
}

export const getConsumptionById = id => async dispatch => {
  dispatch({ type: 'CONSUMPTION/REQUEST/INITIATED' })
  try {
    const result = await consumptionService.getConsumptionById(id)
    if (result.data.success) {
      return dispatch({
        type: 'CONSUMPTION/REQUEST/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'CONSUMPTION/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'CONSUMPTION/REQUEST/FAILED', error })
  }
}

export const approveConsumptionById = id => async dispatch => {
  dispatch({ type: 'CONSUMPTION/APPROVE/INITIATED' })
  try {
    const result = await consumptionService.getConsumptionById(id)
    if (result.data.success) {
      return dispatch({
        type: 'CONSUMPTION/APPROVE/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'CONSUMPTION/APPROVE/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'CONSUMPTION/APPROVE/FAILED', error })
  }
}

export const rejectConsumptionById = id => async dispatch => {
  dispatch({ type: 'CONSUMPTION/REJECT/INITIATED' })
  try {
    const result = await consumptionService.getConsumptionById(id)
    if (result.data.success) {
      return dispatch({
        type: 'CONSUMPTION/REJECT/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'CONSUMPTION/REJECT/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'CONSUMPTION/REJECT/FAILED', error })
  }
}
