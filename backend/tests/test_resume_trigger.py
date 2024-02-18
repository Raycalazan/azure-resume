import pytest
from unittest.mock import MagicMock
from azure.functions import HttpRequest, HttpResponse, Document, Out
from api.resume_trigger import main

def test_main_function_with_mocked_bindings(monkeypatch):
    # Mocking HttpRequest
    req = HttpRequest(
        method='GET',
        url='/api/resume_trigger',
        body=[]
    )

    # Mocking DocumentList and Out bindings
    mock_input_doc = Document({"Count": 5})  # Sample input document
    mock_output_doc = MagicMock(spec=Out)
    
    # Patching getNewCounterValue function to return a predefined value
    monkeypatch.setattr('api.resume_trigger.getNewCounterValue', MagicMock(return_value=5))

    # Calling the Azure Function
    result = main(req, [mock_input_doc], mock_output_doc)

    # Asserting the response
    assert isinstance(result, HttpResponse)
    assert result.status_code == 200
    assert result.get_body().decode() == "6"

    # Asserting the interaction with the output binding
    mock_output_doc.set.assert_called_once_with(mock_input_doc)
