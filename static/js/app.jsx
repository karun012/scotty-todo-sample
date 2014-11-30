define(['react', 'http', 'underscore', 'underscore.string'], function (React, http, _, _s) {
    'use strict';

    var app, TodoAdd, TodoList, TodoApp, TodoElement;

    TodoAdd = React.createClass({
        getInitialState: function () {
            return {
                text: ''
            };
        },
        update: function (event) {
            this.setState({text: event.target.value});
        },
        addTodo: function () {
            var text = _s.trim(this.state.text);
            console.log(text);
            if (!_s.isBlank(text)) {
                this.setState({text: ''});
                this.props.addItem(this.state.text);
                this.refs.todoInput.getDOMNode().focus();
            }
        },
        render: function () {
            return <div className="col-xs-8 form-inline">
                           <input type="text" className="col-xs-4 form-control" value={this.state.value} onChange={this.update} ref="todoInput"/>
                           <button className="col-xs-4 btn btn-primary" onClick={this.addTodo}>Add</button>
                   </div>
        }
    });

    TodoElement = React.createClass({
        getInitialState: function () {
            return this.props;
        },
        render: function () {
            return <li>
                       <span>{this.state.text}</span>
                   </li>
        }
    });

    TodoList = React.createClass({
        render: function () {
            var todoItems;
            todoItems = this.props.data.map(function (todo) {
                return <TodoElement key={todo.uid} id={todo.uid} text={todo.text}/>
            });
            return <ul className="col-xs-6" todo-items>{todoItems}</ul>;
        }
    });

    TodoApp = React.createClass({
        getInitialState: function () {
            return {
                data: []
            };
        },
        componentDidMount: function () {
            var self = this, pushArray;
            pushArray = function pushArray (arr1, arr2) {
                arr1.push.apply(arr1, arr2);
            };
            http({uri: '/todos', method: 'GET'}).then(function (response) {
                pushArray(self.state.data, response);
                self.refreshState();
            });
        },
        addItem: function (text) {
            var todo, self;
            self = this;
            todo = { text: text };
            http({uri: 'todo', method: 'POST', body: todo}).then(function (response, createdAt) {
                var todoWithId = _.extend(todo, {uid: createdAt});
                self.todoAdded(todoWithId);
            });
        },
        todoAdded: function (todo) {
            this.state.data.push(todo);
            this.refreshState();
        },
        refreshState: function () {
            this.setState(this.state);
        },
        render: function () {
            return <section className="grid-row">
                       <div className="col-xs-12">
                           <div className="grid-row">
                               <TodoAdd addItem={this.addItem} />
                           </div>
                           <div className="grid-row">
                               <TodoList data={this.state.data} />
                           </div>
                       </div>
                   </section>;
        }
    });
    
    app = function app(parameters) {
        var mount, todoApp;
        mount = parameters.mount;
        todoApp = <TodoApp/>;
        React.render(todoApp, mount);
    };

    return app;
});
