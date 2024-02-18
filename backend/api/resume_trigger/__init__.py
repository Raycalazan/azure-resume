import logging
import azure.functions as func

def getNewCounterValue(value: int):
    return value

def main(req: func.HttpRequest, inputDocument: func.DocumentList, outputDoc: func.Out[func.Document]) -> func.HttpResponse:
    try:
        logging.info('Python HTTP trigger function processed a request.')

        counter = getNewCounterValue(inputDocument[0]['Count']) + 1
        inputDocument[0]['Count'] = counter
        outputDoc.set(func.Document.from_json(inputDocument[0].to_json()))

        if counter:
            return func.HttpResponse(f"{counter}", status_code=200)
        else:
            return func.HttpResponse("Error", status_code=500)

    except Exception as e:
        # Log the error message
        logging.error(f"An error occurred: {str(e)}")
        return func.HttpResponse("Internal Server Error", status_code=500)
