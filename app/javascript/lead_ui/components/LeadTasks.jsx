import React from 'react'
import Style from './LeadTasks.scss'
import LeadRow from './LeadRow'

class LeadTasks extends React.Component {

  taskPendingIndicator(task) {
    if (task.due) {
      return(<span className={Style.PendingIndicator}>&bull;</span>)
    } else {
      return('')
    }
  }

  taskItem(task) {
    if (task === undefined) {
      return('')
    }

    return(
      <div key={task.id} className={Style.TaskItem}>
        <div className="row">
          <div className="col-md-12">
            {this.taskPendingIndicator(task)}
            <span className={Style.TaskDateTime}>
              {task.schedule_description}
            </span>
          </div>
        </div>
        <div className="row">
          <div className="col-md-1">
            check
          </div>
          <div className="col-md-11">
            {task.description}
          </div>
        </div>
      </div>
    )
  }

  render() {
    const taskItems = ( this.props.lead.tasks || [] ).map((t) => this.taskItem(t))
    return(
      <div className={Style.LeadTasks}>
        <LeadRow add=''>
          <div className="col-md-12">
            <b>Tasks</b>
            {taskItems}
          </div>
        </LeadRow>
      </div>
    )
  }
}

export default LeadTasks
