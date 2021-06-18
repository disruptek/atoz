
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Forecast Service
## version: 2018-06-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Provides APIs for creating and managing Amazon Forecast resources.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/forecast/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                       default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
                                                            ## a suitable default value when appropriate
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Https: {"ap-northeast-1": "forecast.ap-northeast-1.amazonaws.com", "ap-southeast-1": "forecast.ap-southeast-1.amazonaws.com",
                               "us-west-2": "forecast.us-west-2.amazonaws.com",
                               "eu-west-2": "forecast.eu-west-2.amazonaws.com", "ap-northeast-3": "forecast.ap-northeast-3.amazonaws.com", "eu-central-1": "forecast.eu-central-1.amazonaws.com",
                               "us-east-2": "forecast.us-east-2.amazonaws.com",
                               "us-east-1": "forecast.us-east-1.amazonaws.com", "cn-northwest-1": "forecast.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "forecast.ap-south-1.amazonaws.com", "eu-north-1": "forecast.eu-north-1.amazonaws.com", "ap-northeast-2": "forecast.ap-northeast-2.amazonaws.com",
                               "us-west-1": "forecast.us-west-1.amazonaws.com", "us-gov-east-1": "forecast.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "forecast.eu-west-3.amazonaws.com", "cn-north-1": "forecast.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "forecast.sa-east-1.amazonaws.com",
                               "eu-west-1": "forecast.eu-west-1.amazonaws.com", "us-gov-west-1": "forecast.us-gov-west-1.amazonaws.com", "ap-southeast-2": "forecast.ap-southeast-2.amazonaws.com", "ca-central-1": "forecast.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "forecast.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "forecast.ap-southeast-1.amazonaws.com",
      "us-west-2": "forecast.us-west-2.amazonaws.com",
      "eu-west-2": "forecast.eu-west-2.amazonaws.com",
      "ap-northeast-3": "forecast.ap-northeast-3.amazonaws.com",
      "eu-central-1": "forecast.eu-central-1.amazonaws.com",
      "us-east-2": "forecast.us-east-2.amazonaws.com",
      "us-east-1": "forecast.us-east-1.amazonaws.com",
      "cn-northwest-1": "forecast.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "forecast.ap-south-1.amazonaws.com",
      "eu-north-1": "forecast.eu-north-1.amazonaws.com",
      "ap-northeast-2": "forecast.ap-northeast-2.amazonaws.com",
      "us-west-1": "forecast.us-west-1.amazonaws.com",
      "us-gov-east-1": "forecast.us-gov-east-1.amazonaws.com",
      "eu-west-3": "forecast.eu-west-3.amazonaws.com",
      "cn-north-1": "forecast.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "forecast.sa-east-1.amazonaws.com",
      "eu-west-1": "forecast.eu-west-1.amazonaws.com",
      "us-gov-west-1": "forecast.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "forecast.ap-southeast-2.amazonaws.com",
      "ca-central-1": "forecast.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "forecast"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateDataset_402656294 = ref object of OpenApiRestCall_402656044
proc url_CreateDataset_402656296(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataset_402656295(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an Amazon Forecast dataset. The information about the dataset that you provide helps Forecast understand how to consume the data for model training. This includes the following:</p> <ul> <li> <p> <i> <code>DataFrequency</code> </i> - How frequently your historical time-series data is collected.</p> </li> <li> <p> <i> <code>Domain</code> </i> and <i> <code>DatasetType</code> </i> - Each dataset has an associated dataset domain and a type within the domain. Amazon Forecast provides a list of predefined domains and types within each domain. For each unique dataset domain and type within the domain, Amazon Forecast requires your data to include a minimum set of predefined fields.</p> </li> <li> <p> <i> <code>Schema</code> </i> - A schema specifies the fields in the dataset, including the field name and data type.</p> </li> </ul> <p>After creating a dataset, you import your training data into it and add the dataset to a dataset group. You use the dataset group to create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets, use the <a>ListDatasets</a> operation.</p> <p>For example Forecast datasets, see the <a href="https://github.com/aws-samples/amazon-forecast-samples/tree/master/data">Amazon Forecast Sample GitHub repository</a>.</p> <note> <p>The <code>Status</code> of a dataset must be <code>ACTIVE</code> before you can import training data. Use the <a>DescribeDataset</a> operation to get the status.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "AmazonForecast.CreateDataset"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_CreateDataset_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon Forecast dataset. The information about the dataset that you provide helps Forecast understand how to consume the data for model training. This includes the following:</p> <ul> <li> <p> <i> <code>DataFrequency</code> </i> - How frequently your historical time-series data is collected.</p> </li> <li> <p> <i> <code>Domain</code> </i> and <i> <code>DatasetType</code> </i> - Each dataset has an associated dataset domain and a type within the domain. Amazon Forecast provides a list of predefined domains and types within each domain. For each unique dataset domain and type within the domain, Amazon Forecast requires your data to include a minimum set of predefined fields.</p> </li> <li> <p> <i> <code>Schema</code> </i> - A schema specifies the fields in the dataset, including the field name and data type.</p> </li> </ul> <p>After creating a dataset, you import your training data into it and add the dataset to a dataset group. You use the dataset group to create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets, use the <a>ListDatasets</a> operation.</p> <p>For example Forecast datasets, see the <a href="https://github.com/aws-samples/amazon-forecast-samples/tree/master/data">Amazon Forecast Sample GitHub repository</a>.</p> <note> <p>The <code>Status</code> of a dataset must be <code>ACTIVE</code> before you can import training data. Use the <a>DescribeDataset</a> operation to get the status.</p> </note>
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_CreateDataset_402656294; body: JsonNode): Recallable =
  ## createDataset
  ## <p>Creates an Amazon Forecast dataset. The information about the dataset that you provide helps Forecast understand how to consume the data for model training. This includes the following:</p> <ul> <li> <p> <i> <code>DataFrequency</code> </i> - How frequently your historical time-series data is collected.</p> </li> <li> <p> <i> <code>Domain</code> </i> and <i> <code>DatasetType</code> </i> - Each dataset has an associated dataset domain and a type within the domain. Amazon Forecast provides a list of predefined domains and types within each domain. For each unique dataset domain and type within the domain, Amazon Forecast requires your data to include a minimum set of predefined fields.</p> </li> <li> <p> <i> <code>Schema</code> </i> - A schema specifies the fields in the dataset, including the field name and data type.</p> </li> </ul> <p>After creating a dataset, you import your training data into it and add the dataset to a dataset group. You use the dataset group to create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets, use the <a>ListDatasets</a> operation.</p> <p>For example Forecast datasets, see the <a href="https://github.com/aws-samples/amazon-forecast-samples/tree/master/data">Amazon Forecast Sample GitHub repository</a>.</p> <note> <p>The <code>Status</code> of a dataset must be <code>ACTIVE</code> before you can import training data. Use the <a>DescribeDataset</a> operation to get the status.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var createDataset* = Call_CreateDataset_402656294(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateDataset",
    validator: validate_CreateDataset_402656295, base: "/",
    makeUrl: url_CreateDataset_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetGroup_402656489 = ref object of OpenApiRestCall_402656044
proc url_CreateDatasetGroup_402656491(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatasetGroup_402656490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a dataset group, which holds a collection of related datasets. You can add datasets to the dataset group when you create the dataset group, or later by using the <a>UpdateDatasetGroup</a> operation.</p> <p>After creating a dataset group and adding datasets, you use the dataset group when you create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets groups, use the <a>ListDatasetGroups</a> operation.</p> <note> <p>The <code>Status</code> of a dataset group must be <code>ACTIVE</code> before you can create use the dataset group to create a predictor. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "AmazonForecast.CreateDatasetGroup"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_CreateDatasetGroup_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a dataset group, which holds a collection of related datasets. You can add datasets to the dataset group when you create the dataset group, or later by using the <a>UpdateDatasetGroup</a> operation.</p> <p>After creating a dataset group and adding datasets, you use the dataset group when you create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets groups, use the <a>ListDatasetGroups</a> operation.</p> <note> <p>The <code>Status</code> of a dataset group must be <code>ACTIVE</code> before you can create use the dataset group to create a predictor. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> </note>
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_CreateDatasetGroup_402656489; body: JsonNode): Recallable =
  ## createDatasetGroup
  ## <p>Creates a dataset group, which holds a collection of related datasets. You can add datasets to the dataset group when you create the dataset group, or later by using the <a>UpdateDatasetGroup</a> operation.</p> <p>After creating a dataset group and adding datasets, you use the dataset group when you create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets groups, use the <a>ListDatasetGroups</a> operation.</p> <note> <p>The <code>Status</code> of a dataset group must be <code>ACTIVE</code> before you can create use the dataset group to create a predictor. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var createDatasetGroup* = Call_CreateDatasetGroup_402656489(
    name: "createDatasetGroup", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateDatasetGroup",
    validator: validate_CreateDatasetGroup_402656490, base: "/",
    makeUrl: url_CreateDatasetGroup_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetImportJob_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateDatasetImportJob_402656506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatasetImportJob_402656505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Imports your training data to an Amazon Forecast dataset. You provide the location of your training data in an Amazon Simple Storage Service (Amazon S3) bucket and the Amazon Resource Name (ARN) of the dataset that you want to import the data to.</p> <p>You must specify a <a>DataSource</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the data. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>The training data must be in CSV format. The delimiter must be a comma (,).</p> <p>You can specify the path to a specific CSV file, the S3 bucket, or to a folder in the S3 bucket. For the latter two cases, Amazon Forecast imports all files up to the limit of 10,000 files.</p> <p>To get a list of all your dataset import jobs, filtered by specified criteria, use the <a>ListDatasetImportJobs</a> operation.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "AmazonForecast.CreateDatasetImportJob"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_CreateDatasetImportJob_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Imports your training data to an Amazon Forecast dataset. You provide the location of your training data in an Amazon Simple Storage Service (Amazon S3) bucket and the Amazon Resource Name (ARN) of the dataset that you want to import the data to.</p> <p>You must specify a <a>DataSource</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the data. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>The training data must be in CSV format. The delimiter must be a comma (,).</p> <p>You can specify the path to a specific CSV file, the S3 bucket, or to a folder in the S3 bucket. For the latter two cases, Amazon Forecast imports all files up to the limit of 10,000 files.</p> <p>To get a list of all your dataset import jobs, filtered by specified criteria, use the <a>ListDatasetImportJobs</a> operation.</p>
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CreateDatasetImportJob_402656504; body: JsonNode): Recallable =
  ## createDatasetImportJob
  ## <p>Imports your training data to an Amazon Forecast dataset. You provide the location of your training data in an Amazon Simple Storage Service (Amazon S3) bucket and the Amazon Resource Name (ARN) of the dataset that you want to import the data to.</p> <p>You must specify a <a>DataSource</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the data. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>The training data must be in CSV format. The delimiter must be a comma (,).</p> <p>You can specify the path to a specific CSV file, the S3 bucket, or to a folder in the S3 bucket. For the latter two cases, Amazon Forecast imports all files up to the limit of 10,000 files.</p> <p>To get a list of all your dataset import jobs, filtered by specified criteria, use the <a>ListDatasetImportJobs</a> operation.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createDatasetImportJob* = Call_CreateDatasetImportJob_402656504(
    name: "createDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateDatasetImportJob",
    validator: validate_CreateDatasetImportJob_402656505, base: "/",
    makeUrl: url_CreateDatasetImportJob_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateForecast_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateForecast_402656521(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateForecast_402656520(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a forecast for each item in the <code>TARGET_TIME_SERIES</code> dataset that was used to train the predictor. This is known as inference. To retrieve the forecast for a single item at low latency, use the operation. To export the complete forecast into your Amazon Simple Storage Service (Amazon S3) bucket, use the <a>CreateForecastExportJob</a> operation.</p> <p>The range of the forecast is determined by the <code>ForecastHorizon</code> value, which you specify in the <a>CreatePredictor</a> request, multiplied by the <code>DataFrequency</code> value, which you specify in the <a>CreateDataset</a> request. When you query a forecast, you can request a specific date range within the forecast.</p> <p>To get a list of all your forecasts, use the <a>ListForecasts</a> operation.</p> <note> <p>The forecasts generated by Amazon Forecast are in the same time zone as the dataset that was used to create the predictor.</p> </note> <p>For more information, see <a>howitworks-forecast</a>.</p> <note> <p>The <code>Status</code> of the forecast must be <code>ACTIVE</code> before you can query or export the forecast. Use the <a>DescribeForecast</a> operation to get the status.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "AmazonForecast.CreateForecast"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_CreateForecast_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a forecast for each item in the <code>TARGET_TIME_SERIES</code> dataset that was used to train the predictor. This is known as inference. To retrieve the forecast for a single item at low latency, use the operation. To export the complete forecast into your Amazon Simple Storage Service (Amazon S3) bucket, use the <a>CreateForecastExportJob</a> operation.</p> <p>The range of the forecast is determined by the <code>ForecastHorizon</code> value, which you specify in the <a>CreatePredictor</a> request, multiplied by the <code>DataFrequency</code> value, which you specify in the <a>CreateDataset</a> request. When you query a forecast, you can request a specific date range within the forecast.</p> <p>To get a list of all your forecasts, use the <a>ListForecasts</a> operation.</p> <note> <p>The forecasts generated by Amazon Forecast are in the same time zone as the dataset that was used to create the predictor.</p> </note> <p>For more information, see <a>howitworks-forecast</a>.</p> <note> <p>The <code>Status</code> of the forecast must be <code>ACTIVE</code> before you can query or export the forecast. Use the <a>DescribeForecast</a> operation to get the status.</p> </note>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_CreateForecast_402656519; body: JsonNode): Recallable =
  ## createForecast
  ## <p>Creates a forecast for each item in the <code>TARGET_TIME_SERIES</code> dataset that was used to train the predictor. This is known as inference. To retrieve the forecast for a single item at low latency, use the operation. To export the complete forecast into your Amazon Simple Storage Service (Amazon S3) bucket, use the <a>CreateForecastExportJob</a> operation.</p> <p>The range of the forecast is determined by the <code>ForecastHorizon</code> value, which you specify in the <a>CreatePredictor</a> request, multiplied by the <code>DataFrequency</code> value, which you specify in the <a>CreateDataset</a> request. When you query a forecast, you can request a specific date range within the forecast.</p> <p>To get a list of all your forecasts, use the <a>ListForecasts</a> operation.</p> <note> <p>The forecasts generated by Amazon Forecast are in the same time zone as the dataset that was used to create the predictor.</p> </note> <p>For more information, see <a>howitworks-forecast</a>.</p> <note> <p>The <code>Status</code> of the forecast must be <code>ACTIVE</code> before you can query or export the forecast. Use the <a>DescribeForecast</a> operation to get the status.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var createForecast* = Call_CreateForecast_402656519(name: "createForecast",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateForecast",
    validator: validate_CreateForecast_402656520, base: "/",
    makeUrl: url_CreateForecast_402656521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateForecastExportJob_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateForecastExportJob_402656536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateForecastExportJob_402656535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Exports a forecast created by the <a>CreateForecast</a> operation to your Amazon Simple Storage Service (Amazon S3) bucket. The forecast file name will match the following conventions:</p> <p>&lt;ForecastExportJobName&gt;_&lt;ExportTimestamp&gt;_&lt;PageNumber&gt;</p> <p>where the &lt;ExportTimestamp&gt; component is in Java SimpleDateFormat (yyyy-MM-ddTHH-mm-ssZ).</p> <p>You must specify a <a>DataDestination</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>For more information, see <a>howitworks-forecast</a>.</p> <p>To get a list of all your forecast export jobs, use the <a>ListForecastExportJobs</a> operation.</p> <note> <p>The <code>Status</code> of the forecast export job must be <code>ACTIVE</code> before you can access the forecast in your Amazon S3 bucket. To get the status, use the <a>DescribeForecastExportJob</a> operation.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "AmazonForecast.CreateForecastExportJob"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_CreateForecastExportJob_402656534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Exports a forecast created by the <a>CreateForecast</a> operation to your Amazon Simple Storage Service (Amazon S3) bucket. The forecast file name will match the following conventions:</p> <p>&lt;ForecastExportJobName&gt;_&lt;ExportTimestamp&gt;_&lt;PageNumber&gt;</p> <p>where the &lt;ExportTimestamp&gt; component is in Java SimpleDateFormat (yyyy-MM-ddTHH-mm-ssZ).</p> <p>You must specify a <a>DataDestination</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>For more information, see <a>howitworks-forecast</a>.</p> <p>To get a list of all your forecast export jobs, use the <a>ListForecastExportJobs</a> operation.</p> <note> <p>The <code>Status</code> of the forecast export job must be <code>ACTIVE</code> before you can access the forecast in your Amazon S3 bucket. To get the status, use the <a>DescribeForecastExportJob</a> operation.</p> </note>
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_CreateForecastExportJob_402656534;
           body: JsonNode): Recallable =
  ## createForecastExportJob
  ## <p>Exports a forecast created by the <a>CreateForecast</a> operation to your Amazon Simple Storage Service (Amazon S3) bucket. The forecast file name will match the following conventions:</p> <p>&lt;ForecastExportJobName&gt;_&lt;ExportTimestamp&gt;_&lt;PageNumber&gt;</p> <p>where the &lt;ExportTimestamp&gt; component is in Java SimpleDateFormat (yyyy-MM-ddTHH-mm-ssZ).</p> <p>You must specify a <a>DataDestination</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>For more information, see <a>howitworks-forecast</a>.</p> <p>To get a list of all your forecast export jobs, use the <a>ListForecastExportJobs</a> operation.</p> <note> <p>The <code>Status</code> of the forecast export job must be <code>ACTIVE</code> before you can access the forecast in your Amazon S3 bucket. To get the status, use the <a>DescribeForecastExportJob</a> operation.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var createForecastExportJob* = Call_CreateForecastExportJob_402656534(
    name: "createForecastExportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateForecastExportJob",
    validator: validate_CreateForecastExportJob_402656535, base: "/",
    makeUrl: url_CreateForecastExportJob_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePredictor_402656549 = ref object of OpenApiRestCall_402656044
proc url_CreatePredictor_402656551(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePredictor_402656550(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an Amazon Forecast predictor.</p> <p>In the request, you provide a dataset group and either specify an algorithm or let Amazon Forecast choose the algorithm for you using AutoML. If you specify an algorithm, you also can override algorithm-specific hyperparameters.</p> <p>Amazon Forecast uses the chosen algorithm to train a model using the latest version of the datasets in the specified dataset group. The result is called a predictor. You then generate a forecast using the <a>CreateForecast</a> operation.</p> <p>After training a model, the <code>CreatePredictor</code> operation also evaluates it. To see the evaluation metrics, use the <a>GetAccuracyMetrics</a> operation. Always review the evaluation metrics before deciding to use the predictor to generate a forecast.</p> <p>Optionally, you can specify a featurization configuration to fill and aggregate the data fields in the <code>TARGET_TIME_SERIES</code> dataset to improve model training. For more information, see <a>FeaturizationConfig</a>.</p> <p>For RELATED_TIME_SERIES datasets, <code>CreatePredictor</code> verifies that the <code>DataFrequency</code> specified when the dataset was created matches the <code>ForecastFrequency</code>. TARGET_TIME_SERIES datasets don't have this restriction. Amazon Forecast also verifies the delimiter and timestamp format. For more information, see <a>howitworks-datasets-groups</a>.</p> <p> <b>AutoML</b> </p> <p>If you want Amazon Forecast to evaluate each algorithm and choose the one that minimizes the <code>objective function</code>, set <code>PerformAutoML</code> to <code>true</code>. The <code>objective function</code> is defined as the mean of the weighted p10, p50, and p90 quantile losses. For more information, see <a>EvaluationResult</a>.</p> <p>When AutoML is enabled, the following properties are disallowed:</p> <ul> <li> <p> <code>AlgorithmArn</code> </p> </li> <li> <p> <code>HPOConfig</code> </p> </li> <li> <p> <code>PerformHPO</code> </p> </li> <li> <p> <code>TrainingParameters</code> </p> </li> </ul> <p>To get a list of all of your predictors, use the <a>ListPredictors</a> operation.</p> <note> <p>Before you can use the predictor to create a forecast, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "AmazonForecast.CreatePredictor"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_CreatePredictor_402656549; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon Forecast predictor.</p> <p>In the request, you provide a dataset group and either specify an algorithm or let Amazon Forecast choose the algorithm for you using AutoML. If you specify an algorithm, you also can override algorithm-specific hyperparameters.</p> <p>Amazon Forecast uses the chosen algorithm to train a model using the latest version of the datasets in the specified dataset group. The result is called a predictor. You then generate a forecast using the <a>CreateForecast</a> operation.</p> <p>After training a model, the <code>CreatePredictor</code> operation also evaluates it. To see the evaluation metrics, use the <a>GetAccuracyMetrics</a> operation. Always review the evaluation metrics before deciding to use the predictor to generate a forecast.</p> <p>Optionally, you can specify a featurization configuration to fill and aggregate the data fields in the <code>TARGET_TIME_SERIES</code> dataset to improve model training. For more information, see <a>FeaturizationConfig</a>.</p> <p>For RELATED_TIME_SERIES datasets, <code>CreatePredictor</code> verifies that the <code>DataFrequency</code> specified when the dataset was created matches the <code>ForecastFrequency</code>. TARGET_TIME_SERIES datasets don't have this restriction. Amazon Forecast also verifies the delimiter and timestamp format. For more information, see <a>howitworks-datasets-groups</a>.</p> <p> <b>AutoML</b> </p> <p>If you want Amazon Forecast to evaluate each algorithm and choose the one that minimizes the <code>objective function</code>, set <code>PerformAutoML</code> to <code>true</code>. The <code>objective function</code> is defined as the mean of the weighted p10, p50, and p90 quantile losses. For more information, see <a>EvaluationResult</a>.</p> <p>When AutoML is enabled, the following properties are disallowed:</p> <ul> <li> <p> <code>AlgorithmArn</code> </p> </li> <li> <p> <code>HPOConfig</code> </p> </li> <li> <p> <code>PerformHPO</code> </p> </li> <li> <p> <code>TrainingParameters</code> </p> </li> </ul> <p>To get a list of all of your predictors, use the <a>ListPredictors</a> operation.</p> <note> <p>Before you can use the predictor to create a forecast, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CreatePredictor_402656549; body: JsonNode): Recallable =
  ## createPredictor
  ## <p>Creates an Amazon Forecast predictor.</p> <p>In the request, you provide a dataset group and either specify an algorithm or let Amazon Forecast choose the algorithm for you using AutoML. If you specify an algorithm, you also can override algorithm-specific hyperparameters.</p> <p>Amazon Forecast uses the chosen algorithm to train a model using the latest version of the datasets in the specified dataset group. The result is called a predictor. You then generate a forecast using the <a>CreateForecast</a> operation.</p> <p>After training a model, the <code>CreatePredictor</code> operation also evaluates it. To see the evaluation metrics, use the <a>GetAccuracyMetrics</a> operation. Always review the evaluation metrics before deciding to use the predictor to generate a forecast.</p> <p>Optionally, you can specify a featurization configuration to fill and aggregate the data fields in the <code>TARGET_TIME_SERIES</code> dataset to improve model training. For more information, see <a>FeaturizationConfig</a>.</p> <p>For RELATED_TIME_SERIES datasets, <code>CreatePredictor</code> verifies that the <code>DataFrequency</code> specified when the dataset was created matches the <code>ForecastFrequency</code>. TARGET_TIME_SERIES datasets don't have this restriction. Amazon Forecast also verifies the delimiter and timestamp format. For more information, see <a>howitworks-datasets-groups</a>.</p> <p> <b>AutoML</b> </p> <p>If you want Amazon Forecast to evaluate each algorithm and choose the one that minimizes the <code>objective function</code>, set <code>PerformAutoML</code> to <code>true</code>. The <code>objective function</code> is defined as the mean of the weighted p10, p50, and p90 quantile losses. For more information, see <a>EvaluationResult</a>.</p> <p>When AutoML is enabled, the following properties are disallowed:</p> <ul> <li> <p> <code>AlgorithmArn</code> </p> </li> <li> <p> <code>HPOConfig</code> </p> </li> <li> <p> <code>PerformHPO</code> </p> </li> <li> <p> <code>TrainingParameters</code> </p> </li> </ul> <p>To get a list of all of your predictors, use the <a>ListPredictors</a> operation.</p> <note> <p>Before you can use the predictor to create a forecast, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createPredictor* = Call_CreatePredictor_402656549(name: "createPredictor",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreatePredictor",
    validator: validate_CreatePredictor_402656550, base: "/",
    makeUrl: url_CreatePredictor_402656551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_402656564 = ref object of OpenApiRestCall_402656044
proc url_DeleteDataset_402656566(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDataset_402656565(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an Amazon Forecast dataset that was created using the <a>CreateDataset</a> operation. You can only delete datasets that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status use the <a>DescribeDataset</a> operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "AmazonForecast.DeleteDataset"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_DeleteDataset_402656564; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Amazon Forecast dataset that was created using the <a>CreateDataset</a> operation. You can only delete datasets that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status use the <a>DescribeDataset</a> operation.
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_DeleteDataset_402656564; body: JsonNode): Recallable =
  ## deleteDataset
  ## Deletes an Amazon Forecast dataset that was created using the <a>CreateDataset</a> operation. You can only delete datasets that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status use the <a>DescribeDataset</a> operation.
  ##   
                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var deleteDataset* = Call_DeleteDataset_402656564(name: "deleteDataset",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteDataset",
    validator: validate_DeleteDataset_402656565, base: "/",
    makeUrl: url_DeleteDataset_402656566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetGroup_402656579 = ref object of OpenApiRestCall_402656044
proc url_DeleteDatasetGroup_402656581(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDatasetGroup_402656580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a dataset group created using the <a>CreateDatasetGroup</a> operation. You can only delete dataset groups that have a status of <code>ACTIVE</code>, <code>CREATE_FAILED</code>, or <code>UPDATE_FAILED</code>. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> <p>This operation deletes only the dataset group, not the datasets in the group.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "AmazonForecast.DeleteDatasetGroup"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_DeleteDatasetGroup_402656579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a dataset group created using the <a>CreateDatasetGroup</a> operation. You can only delete dataset groups that have a status of <code>ACTIVE</code>, <code>CREATE_FAILED</code>, or <code>UPDATE_FAILED</code>. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> <p>This operation deletes only the dataset group, not the datasets in the group.</p>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_DeleteDatasetGroup_402656579; body: JsonNode): Recallable =
  ## deleteDatasetGroup
  ## <p>Deletes a dataset group created using the <a>CreateDatasetGroup</a> operation. You can only delete dataset groups that have a status of <code>ACTIVE</code>, <code>CREATE_FAILED</code>, or <code>UPDATE_FAILED</code>. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> <p>This operation deletes only the dataset group, not the datasets in the group.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var deleteDatasetGroup* = Call_DeleteDatasetGroup_402656579(
    name: "deleteDatasetGroup", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteDatasetGroup",
    validator: validate_DeleteDatasetGroup_402656580, base: "/",
    makeUrl: url_DeleteDatasetGroup_402656581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetImportJob_402656594 = ref object of OpenApiRestCall_402656044
proc url_DeleteDatasetImportJob_402656596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDatasetImportJob_402656595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a dataset import job created using the <a>CreateDatasetImportJob</a> operation. You can delete only dataset import jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeDatasetImportJob</a> operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "AmazonForecast.DeleteDatasetImportJob"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_DeleteDatasetImportJob_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a dataset import job created using the <a>CreateDatasetImportJob</a> operation. You can delete only dataset import jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeDatasetImportJob</a> operation.
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_DeleteDatasetImportJob_402656594; body: JsonNode): Recallable =
  ## deleteDatasetImportJob
  ## Deletes a dataset import job created using the <a>CreateDatasetImportJob</a> operation. You can delete only dataset import jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeDatasetImportJob</a> operation.
  ##   
                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var deleteDatasetImportJob* = Call_DeleteDatasetImportJob_402656594(
    name: "deleteDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteDatasetImportJob",
    validator: validate_DeleteDatasetImportJob_402656595, base: "/",
    makeUrl: url_DeleteDatasetImportJob_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteForecast_402656609 = ref object of OpenApiRestCall_402656044
proc url_DeleteForecast_402656611(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteForecast_402656610(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes a forecast created using the <a>CreateForecast</a> operation. You can delete only forecasts that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecast</a> operation.</p> <p>You can't delete a forecast while it is being exported. After a forecast is deleted, you can no longer query the forecast.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "AmazonForecast.DeleteForecast"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_DeleteForecast_402656609; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a forecast created using the <a>CreateForecast</a> operation. You can delete only forecasts that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecast</a> operation.</p> <p>You can't delete a forecast while it is being exported. After a forecast is deleted, you can no longer query the forecast.</p>
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_DeleteForecast_402656609; body: JsonNode): Recallable =
  ## deleteForecast
  ## <p>Deletes a forecast created using the <a>CreateForecast</a> operation. You can delete only forecasts that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecast</a> operation.</p> <p>You can't delete a forecast while it is being exported. After a forecast is deleted, you can no longer query the forecast.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var deleteForecast* = Call_DeleteForecast_402656609(name: "deleteForecast",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteForecast",
    validator: validate_DeleteForecast_402656610, base: "/",
    makeUrl: url_DeleteForecast_402656611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteForecastExportJob_402656624 = ref object of OpenApiRestCall_402656044
proc url_DeleteForecastExportJob_402656626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteForecastExportJob_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a forecast export job created using the <a>CreateForecastExportJob</a> operation. You can delete only export jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecastExportJob</a> operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "AmazonForecast.DeleteForecastExportJob"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_DeleteForecastExportJob_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a forecast export job created using the <a>CreateForecastExportJob</a> operation. You can delete only export jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecastExportJob</a> operation.
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_DeleteForecastExportJob_402656624;
           body: JsonNode): Recallable =
  ## deleteForecastExportJob
  ## Deletes a forecast export job created using the <a>CreateForecastExportJob</a> operation. You can delete only export jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecastExportJob</a> operation.
  ##   
                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var deleteForecastExportJob* = Call_DeleteForecastExportJob_402656624(
    name: "deleteForecastExportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteForecastExportJob",
    validator: validate_DeleteForecastExportJob_402656625, base: "/",
    makeUrl: url_DeleteForecastExportJob_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePredictor_402656639 = ref object of OpenApiRestCall_402656044
proc url_DeletePredictor_402656641(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePredictor_402656640(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a predictor created using the <a>CreatePredictor</a> operation. You can delete only predictor that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribePredictor</a> operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "AmazonForecast.DeletePredictor"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_DeletePredictor_402656639; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a predictor created using the <a>CreatePredictor</a> operation. You can delete only predictor that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribePredictor</a> operation.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DeletePredictor_402656639; body: JsonNode): Recallable =
  ## deletePredictor
  ## Deletes a predictor created using the <a>CreatePredictor</a> operation. You can delete only predictor that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribePredictor</a> operation.
  ##   
                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var deletePredictor* = Call_DeletePredictor_402656639(name: "deletePredictor",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeletePredictor",
    validator: validate_DeletePredictor_402656640, base: "/",
    makeUrl: url_DeletePredictor_402656641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_402656654 = ref object of OpenApiRestCall_402656044
proc url_DescribeDataset_402656656(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDataset_402656655(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes an Amazon Forecast dataset created using the <a>CreateDataset</a> operation.</p> <p>In addition to listing the parameters specified in the <code>CreateDataset</code> request, this operation includes the following dataset properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "AmazonForecast.DescribeDataset"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_DescribeDataset_402656654; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes an Amazon Forecast dataset created using the <a>CreateDataset</a> operation.</p> <p>In addition to listing the parameters specified in the <code>CreateDataset</code> request, this operation includes the following dataset properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_DescribeDataset_402656654; body: JsonNode): Recallable =
  ## describeDataset
  ## <p>Describes an Amazon Forecast dataset created using the <a>CreateDataset</a> operation.</p> <p>In addition to listing the parameters specified in the <code>CreateDataset</code> request, this operation includes the following dataset properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var describeDataset* = Call_DescribeDataset_402656654(name: "describeDataset",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeDataset",
    validator: validate_DescribeDataset_402656655, base: "/",
    makeUrl: url_DescribeDataset_402656656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatasetGroup_402656669 = ref object of OpenApiRestCall_402656044
proc url_DescribeDatasetGroup_402656671(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDatasetGroup_402656670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes a dataset group created using the <a>CreateDatasetGroup</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetGroup</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>DatasetArns</code> - The datasets belonging to the group.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "AmazonForecast.DescribeDatasetGroup"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_DescribeDatasetGroup_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes a dataset group created using the <a>CreateDatasetGroup</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetGroup</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>DatasetArns</code> - The datasets belonging to the group.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DescribeDatasetGroup_402656669; body: JsonNode): Recallable =
  ## describeDatasetGroup
  ## <p>Describes a dataset group created using the <a>CreateDatasetGroup</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetGroup</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>DatasetArns</code> - The datasets belonging to the group.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var describeDatasetGroup* = Call_DescribeDatasetGroup_402656669(
    name: "describeDatasetGroup", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeDatasetGroup",
    validator: validate_DescribeDatasetGroup_402656670, base: "/",
    makeUrl: url_DescribeDatasetGroup_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatasetImportJob_402656684 = ref object of OpenApiRestCall_402656044
proc url_DescribeDatasetImportJob_402656686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDatasetImportJob_402656685(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Describes a dataset import job created using the <a>CreateDatasetImportJob</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetImportJob</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>DataSize</code> </p> </li> <li> <p> <code>FieldStatistics</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "AmazonForecast.DescribeDatasetImportJob"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656696: Call_DescribeDatasetImportJob_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes a dataset import job created using the <a>CreateDatasetImportJob</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetImportJob</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>DataSize</code> </p> </li> <li> <p> <code>FieldStatistics</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_DescribeDatasetImportJob_402656684;
           body: JsonNode): Recallable =
  ## describeDatasetImportJob
  ## <p>Describes a dataset import job created using the <a>CreateDatasetImportJob</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetImportJob</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>DataSize</code> </p> </li> <li> <p> <code>FieldStatistics</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var describeDatasetImportJob* = Call_DescribeDatasetImportJob_402656684(
    name: "describeDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeDatasetImportJob",
    validator: validate_DescribeDatasetImportJob_402656685, base: "/",
    makeUrl: url_DescribeDatasetImportJob_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeForecast_402656699 = ref object of OpenApiRestCall_402656044
proc url_DescribeForecast_402656701(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeForecast_402656700(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes a forecast created using the <a>CreateForecast</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreateForecast</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetGroupArn</code> - The dataset group that provided the training data.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "AmazonForecast.DescribeForecast"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_DescribeForecast_402656699;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes a forecast created using the <a>CreateForecast</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreateForecast</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetGroupArn</code> - The dataset group that provided the training data.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_DescribeForecast_402656699; body: JsonNode): Recallable =
  ## describeForecast
  ## <p>Describes a forecast created using the <a>CreateForecast</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreateForecast</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetGroupArn</code> - The dataset group that provided the training data.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var describeForecast* = Call_DescribeForecast_402656699(
    name: "describeForecast", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeForecast",
    validator: validate_DescribeForecast_402656700, base: "/",
    makeUrl: url_DescribeForecast_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeForecastExportJob_402656714 = ref object of OpenApiRestCall_402656044
proc url_DescribeForecastExportJob_402656716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeForecastExportJob_402656715(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Describes a forecast export job created using the <a>CreateForecastExportJob</a> operation.</p> <p>In addition to listing the properties provided by the user in the <code>CreateForecastExportJob</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "AmazonForecast.DescribeForecastExportJob"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656726: Call_DescribeForecastExportJob_402656714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes a forecast export job created using the <a>CreateForecastExportJob</a> operation.</p> <p>In addition to listing the properties provided by the user in the <code>CreateForecastExportJob</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_DescribeForecastExportJob_402656714;
           body: JsonNode): Recallable =
  ## describeForecastExportJob
  ## <p>Describes a forecast export job created using the <a>CreateForecastExportJob</a> operation.</p> <p>In addition to listing the properties provided by the user in the <code>CreateForecastExportJob</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var describeForecastExportJob* = Call_DescribeForecastExportJob_402656714(
    name: "describeForecastExportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeForecastExportJob",
    validator: validate_DescribeForecastExportJob_402656715, base: "/",
    makeUrl: url_DescribeForecastExportJob_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePredictor_402656729 = ref object of OpenApiRestCall_402656044
proc url_DescribePredictor_402656731(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePredictor_402656730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Describes a predictor created using the <a>CreatePredictor</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreatePredictor</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetImportJobArns</code> - The dataset import jobs used to import training data.</p> </li> <li> <p> <code>AutoMLAlgorithmArns</code> - If AutoML is performed, the algorithms that were evaluated.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "AmazonForecast.DescribePredictor"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656741: Call_DescribePredictor_402656729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes a predictor created using the <a>CreatePredictor</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreatePredictor</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetImportJobArns</code> - The dataset import jobs used to import training data.</p> </li> <li> <p> <code>AutoMLAlgorithmArns</code> - If AutoML is performed, the algorithms that were evaluated.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_DescribePredictor_402656729; body: JsonNode): Recallable =
  ## describePredictor
  ## <p>Describes a predictor created using the <a>CreatePredictor</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreatePredictor</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetImportJobArns</code> - The dataset import jobs used to import training data.</p> </li> <li> <p> <code>AutoMLAlgorithmArns</code> - If AutoML is performed, the algorithms that were evaluated.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var describePredictor* = Call_DescribePredictor_402656729(
    name: "describePredictor", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribePredictor",
    validator: validate_DescribePredictor_402656730, base: "/",
    makeUrl: url_DescribePredictor_402656731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccuracyMetrics_402656744 = ref object of OpenApiRestCall_402656044
proc url_GetAccuracyMetrics_402656746(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccuracyMetrics_402656745(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Provides metrics on the accuracy of the models that were trained by the <a>CreatePredictor</a> operation. Use metrics to see how well the model performed and to decide whether to use the predictor to generate a forecast. For more information, see <a>metrics</a>.</p> <p>This operation generates metrics for each backtest window that was evaluated. The number of backtest windows (<code>NumberOfBacktestWindows</code>) is specified using the <a>EvaluationParameters</a> object, which is optionally included in the <code>CreatePredictor</code> request. If <code>NumberOfBacktestWindows</code> isn't specified, the number defaults to one.</p> <p>The parameters of the <code>filling</code> method determine which items contribute to the metrics. If you want all items to contribute, specify <code>zero</code>. If you want only those items that have complete data in the range being evaluated to contribute, specify <code>nan</code>. For more information, see <a>FeaturizationMethod</a>.</p> <note> <p>Before you can get accuracy metrics, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "AmazonForecast.GetAccuracyMetrics"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656756: Call_GetAccuracyMetrics_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Provides metrics on the accuracy of the models that were trained by the <a>CreatePredictor</a> operation. Use metrics to see how well the model performed and to decide whether to use the predictor to generate a forecast. For more information, see <a>metrics</a>.</p> <p>This operation generates metrics for each backtest window that was evaluated. The number of backtest windows (<code>NumberOfBacktestWindows</code>) is specified using the <a>EvaluationParameters</a> object, which is optionally included in the <code>CreatePredictor</code> request. If <code>NumberOfBacktestWindows</code> isn't specified, the number defaults to one.</p> <p>The parameters of the <code>filling</code> method determine which items contribute to the metrics. If you want all items to contribute, specify <code>zero</code>. If you want only those items that have complete data in the range being evaluated to contribute, specify <code>nan</code>. For more information, see <a>FeaturizationMethod</a>.</p> <note> <p>Before you can get accuracy metrics, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_GetAccuracyMetrics_402656744; body: JsonNode): Recallable =
  ## getAccuracyMetrics
  ## <p>Provides metrics on the accuracy of the models that were trained by the <a>CreatePredictor</a> operation. Use metrics to see how well the model performed and to decide whether to use the predictor to generate a forecast. For more information, see <a>metrics</a>.</p> <p>This operation generates metrics for each backtest window that was evaluated. The number of backtest windows (<code>NumberOfBacktestWindows</code>) is specified using the <a>EvaluationParameters</a> object, which is optionally included in the <code>CreatePredictor</code> request. If <code>NumberOfBacktestWindows</code> isn't specified, the number defaults to one.</p> <p>The parameters of the <code>filling</code> method determine which items contribute to the metrics. If you want all items to contribute, specify <code>zero</code>. If you want only those items that have complete data in the range being evaluated to contribute, specify <code>nan</code>. For more information, see <a>FeaturizationMethod</a>.</p> <note> <p>Before you can get accuracy metrics, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var getAccuracyMetrics* = Call_GetAccuracyMetrics_402656744(
    name: "getAccuracyMetrics", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.GetAccuracyMetrics",
    validator: validate_GetAccuracyMetrics_402656745, base: "/",
    makeUrl: url_GetAccuracyMetrics_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetGroups_402656759 = ref object of OpenApiRestCall_402656044
proc url_ListDatasetGroups_402656761(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasetGroups_402656760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of dataset groups created using the <a>CreateDatasetGroup</a> operation. For each dataset group, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the dataset group ARN with the <a>DescribeDatasetGroup</a> operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656762 = query.getOrDefault("MaxResults")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "MaxResults", valid_402656762
  var valid_402656763 = query.getOrDefault("NextToken")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "NextToken", valid_402656763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656764 = header.getOrDefault("X-Amz-Target")
  valid_402656764 = validateParameter(valid_402656764, JString, required = true, default = newJString(
      "AmazonForecast.ListDatasetGroups"))
  if valid_402656764 != nil:
    section.add "X-Amz-Target", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Security-Token", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Signature")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Signature", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Algorithm", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Date")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Date", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Credential")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Credential", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656773: Call_ListDatasetGroups_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of dataset groups created using the <a>CreateDatasetGroup</a> operation. For each dataset group, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the dataset group ARN with the <a>DescribeDatasetGroup</a> operation.
                                                                                         ## 
  let valid = call_402656773.validator(path, query, header, formData, body, _)
  let scheme = call_402656773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656773.makeUrl(scheme.get, call_402656773.host, call_402656773.base,
                                   call_402656773.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656773, uri, valid, _)

proc call*(call_402656774: Call_ListDatasetGroups_402656759; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDatasetGroups
  ## Returns a list of dataset groups created using the <a>CreateDatasetGroup</a> operation. For each dataset group, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the dataset group ARN with the <a>DescribeDatasetGroup</a> operation.
  ##   
                                                                                                                                                                                                                                                                                                                                                 ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                    ## token
  var query_402656775 = newJObject()
  var body_402656776 = newJObject()
  add(query_402656775, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656776 = body
  add(query_402656775, "NextToken", newJString(NextToken))
  result = call_402656774.call(nil, query_402656775, nil, nil, body_402656776)

var listDatasetGroups* = Call_ListDatasetGroups_402656759(
    name: "listDatasetGroups", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListDatasetGroups",
    validator: validate_ListDatasetGroups_402656760, base: "/",
    makeUrl: url_ListDatasetGroups_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetImportJobs_402656777 = ref object of OpenApiRestCall_402656044
proc url_ListDatasetImportJobs_402656779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasetImportJobs_402656778(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of dataset import jobs created using the <a>CreateDatasetImportJob</a> operation. For each import job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribeDatasetImportJob</a> operation. You can filter the list by providing an array of <a>Filter</a> objects.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656780 = query.getOrDefault("MaxResults")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "MaxResults", valid_402656780
  var valid_402656781 = query.getOrDefault("NextToken")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "NextToken", valid_402656781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656782 = header.getOrDefault("X-Amz-Target")
  valid_402656782 = validateParameter(valid_402656782, JString, required = true, default = newJString(
      "AmazonForecast.ListDatasetImportJobs"))
  if valid_402656782 != nil:
    section.add "X-Amz-Target", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Security-Token", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Signature")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Signature", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Algorithm", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Date")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Date", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Credential")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Credential", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656791: Call_ListDatasetImportJobs_402656777;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of dataset import jobs created using the <a>CreateDatasetImportJob</a> operation. For each import job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribeDatasetImportJob</a> operation. You can filter the list by providing an array of <a>Filter</a> objects.
                                                                                         ## 
  let valid = call_402656791.validator(path, query, header, formData, body, _)
  let scheme = call_402656791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656791.makeUrl(scheme.get, call_402656791.host, call_402656791.base,
                                   call_402656791.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656791, uri, valid, _)

proc call*(call_402656792: Call_ListDatasetImportJobs_402656777; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDatasetImportJobs
  ## Returns a list of dataset import jobs created using the <a>CreateDatasetImportJob</a> operation. For each import job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribeDatasetImportJob</a> operation. You can filter the list by providing an array of <a>Filter</a> objects.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                     ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                     ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## token
  var query_402656793 = newJObject()
  var body_402656794 = newJObject()
  add(query_402656793, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656794 = body
  add(query_402656793, "NextToken", newJString(NextToken))
  result = call_402656792.call(nil, query_402656793, nil, nil, body_402656794)

var listDatasetImportJobs* = Call_ListDatasetImportJobs_402656777(
    name: "listDatasetImportJobs", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListDatasetImportJobs",
    validator: validate_ListDatasetImportJobs_402656778, base: "/",
    makeUrl: url_ListDatasetImportJobs_402656779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_402656795 = ref object of OpenApiRestCall_402656044
proc url_ListDatasets_402656797(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasets_402656796(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of datasets created using the <a>CreateDataset</a> operation. For each dataset, a summary of its properties, including its Amazon Resource Name (ARN), is returned. To retrieve the complete set of properties, use the ARN with the <a>DescribeDataset</a> operation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656798 = query.getOrDefault("MaxResults")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "MaxResults", valid_402656798
  var valid_402656799 = query.getOrDefault("NextToken")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "NextToken", valid_402656799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656800 = header.getOrDefault("X-Amz-Target")
  valid_402656800 = validateParameter(valid_402656800, JString, required = true, default = newJString(
      "AmazonForecast.ListDatasets"))
  if valid_402656800 != nil:
    section.add "X-Amz-Target", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Security-Token", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Signature")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Signature", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Algorithm", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Date")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Date", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Credential")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Credential", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656809: Call_ListDatasets_402656795; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of datasets created using the <a>CreateDataset</a> operation. For each dataset, a summary of its properties, including its Amazon Resource Name (ARN), is returned. To retrieve the complete set of properties, use the ARN with the <a>DescribeDataset</a> operation.
                                                                                         ## 
  let valid = call_402656809.validator(path, query, header, formData, body, _)
  let scheme = call_402656809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656809.makeUrl(scheme.get, call_402656809.host, call_402656809.base,
                                   call_402656809.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656809, uri, valid, _)

proc call*(call_402656810: Call_ListDatasets_402656795; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDatasets
  ## Returns a list of datasets created using the <a>CreateDataset</a> operation. For each dataset, a summary of its properties, including its Amazon Resource Name (ARN), is returned. To retrieve the complete set of properties, use the ARN with the <a>DescribeDataset</a> operation.
  ##   
                                                                                                                                                                                                                                                                                          ## MaxResults: string
                                                                                                                                                                                                                                                                                          ##             
                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                          ## limit
  ##   
                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                             ## NextToken: string
                                                                                                                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                             ## token
  var query_402656811 = newJObject()
  var body_402656812 = newJObject()
  add(query_402656811, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656812 = body
  add(query_402656811, "NextToken", newJString(NextToken))
  result = call_402656810.call(nil, query_402656811, nil, nil, body_402656812)

var listDatasets* = Call_ListDatasets_402656795(name: "listDatasets",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListDatasets",
    validator: validate_ListDatasets_402656796, base: "/",
    makeUrl: url_ListDatasets_402656797, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListForecastExportJobs_402656813 = ref object of OpenApiRestCall_402656044
proc url_ListForecastExportJobs_402656815(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListForecastExportJobs_402656814(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of forecast export jobs created using the <a>CreateForecastExportJob</a> operation. For each forecast export job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, use the ARN with the <a>DescribeForecastExportJob</a> operation. You can filter the list using an array of <a>Filter</a> objects.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656816 = query.getOrDefault("MaxResults")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "MaxResults", valid_402656816
  var valid_402656817 = query.getOrDefault("NextToken")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "NextToken", valid_402656817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656818 = header.getOrDefault("X-Amz-Target")
  valid_402656818 = validateParameter(valid_402656818, JString, required = true, default = newJString(
      "AmazonForecast.ListForecastExportJobs"))
  if valid_402656818 != nil:
    section.add "X-Amz-Target", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Security-Token", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Signature")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Signature", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Algorithm", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Date")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Date", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Credential")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Credential", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656827: Call_ListForecastExportJobs_402656813;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of forecast export jobs created using the <a>CreateForecastExportJob</a> operation. For each forecast export job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, use the ARN with the <a>DescribeForecastExportJob</a> operation. You can filter the list using an array of <a>Filter</a> objects.
                                                                                         ## 
  let valid = call_402656827.validator(path, query, header, formData, body, _)
  let scheme = call_402656827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656827.makeUrl(scheme.get, call_402656827.host, call_402656827.base,
                                   call_402656827.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656827, uri, valid, _)

proc call*(call_402656828: Call_ListForecastExportJobs_402656813;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listForecastExportJobs
  ## Returns a list of forecast export jobs created using the <a>CreateForecastExportJob</a> operation. For each forecast export job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, use the ARN with the <a>DescribeForecastExportJob</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                 ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## token
  var query_402656829 = newJObject()
  var body_402656830 = newJObject()
  add(query_402656829, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656830 = body
  add(query_402656829, "NextToken", newJString(NextToken))
  result = call_402656828.call(nil, query_402656829, nil, nil, body_402656830)

var listForecastExportJobs* = Call_ListForecastExportJobs_402656813(
    name: "listForecastExportJobs", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListForecastExportJobs",
    validator: validate_ListForecastExportJobs_402656814, base: "/",
    makeUrl: url_ListForecastExportJobs_402656815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListForecasts_402656831 = ref object of OpenApiRestCall_402656044
proc url_ListForecasts_402656833(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListForecasts_402656832(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of forecasts created using the <a>CreateForecast</a> operation. For each forecast, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, specify the ARN with the <a>DescribeForecast</a> operation. You can filter the list using an array of <a>Filter</a> objects.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656834 = query.getOrDefault("MaxResults")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "MaxResults", valid_402656834
  var valid_402656835 = query.getOrDefault("NextToken")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "NextToken", valid_402656835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656836 = header.getOrDefault("X-Amz-Target")
  valid_402656836 = validateParameter(valid_402656836, JString, required = true, default = newJString(
      "AmazonForecast.ListForecasts"))
  if valid_402656836 != nil:
    section.add "X-Amz-Target", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Security-Token", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Signature")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Signature", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Algorithm", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Date")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Date", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Credential")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Credential", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656845: Call_ListForecasts_402656831; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of forecasts created using the <a>CreateForecast</a> operation. For each forecast, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, specify the ARN with the <a>DescribeForecast</a> operation. You can filter the list using an array of <a>Filter</a> objects.
                                                                                         ## 
  let valid = call_402656845.validator(path, query, header, formData, body, _)
  let scheme = call_402656845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656845.makeUrl(scheme.get, call_402656845.host, call_402656845.base,
                                   call_402656845.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656845, uri, valid, _)

proc call*(call_402656846: Call_ListForecasts_402656831; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listForecasts
  ## Returns a list of forecasts created using the <a>CreateForecast</a> operation. For each forecast, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, specify the ARN with the <a>DescribeForecast</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ##   
                                                                                                                                                                                                                                                                                                                                                                             ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                             ##             
                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                             ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                             ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                ## token
  var query_402656847 = newJObject()
  var body_402656848 = newJObject()
  add(query_402656847, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656848 = body
  add(query_402656847, "NextToken", newJString(NextToken))
  result = call_402656846.call(nil, query_402656847, nil, nil, body_402656848)

var listForecasts* = Call_ListForecasts_402656831(name: "listForecasts",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListForecasts",
    validator: validate_ListForecasts_402656832, base: "/",
    makeUrl: url_ListForecasts_402656833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPredictors_402656849 = ref object of OpenApiRestCall_402656044
proc url_ListPredictors_402656851(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPredictors_402656850(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of predictors created using the <a>CreatePredictor</a> operation. For each predictor, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribePredictor</a> operation. You can filter the list using an array of <a>Filter</a> objects.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656852 = query.getOrDefault("MaxResults")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "MaxResults", valid_402656852
  var valid_402656853 = query.getOrDefault("NextToken")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "NextToken", valid_402656853
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656854 = header.getOrDefault("X-Amz-Target")
  valid_402656854 = validateParameter(valid_402656854, JString, required = true, default = newJString(
      "AmazonForecast.ListPredictors"))
  if valid_402656854 != nil:
    section.add "X-Amz-Target", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Security-Token", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Signature")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Signature", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Algorithm", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Date")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Date", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Credential")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Credential", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656863: Call_ListPredictors_402656849; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of predictors created using the <a>CreatePredictor</a> operation. For each predictor, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribePredictor</a> operation. You can filter the list using an array of <a>Filter</a> objects.
                                                                                         ## 
  let valid = call_402656863.validator(path, query, header, formData, body, _)
  let scheme = call_402656863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656863.makeUrl(scheme.get, call_402656863.host, call_402656863.base,
                                   call_402656863.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656863, uri, valid, _)

proc call*(call_402656864: Call_ListPredictors_402656849; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPredictors
  ## Returns a list of predictors created using the <a>CreatePredictor</a> operation. For each predictor, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribePredictor</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                      ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                      ##             
                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                      ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                         ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                         ## token
  var query_402656865 = newJObject()
  var body_402656866 = newJObject()
  add(query_402656865, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656866 = body
  add(query_402656865, "NextToken", newJString(NextToken))
  result = call_402656864.call(nil, query_402656865, nil, nil, body_402656866)

var listPredictors* = Call_ListPredictors_402656849(name: "listPredictors",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListPredictors",
    validator: validate_ListPredictors_402656850, base: "/",
    makeUrl: url_ListPredictors_402656851, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatasetGroup_402656867 = ref object of OpenApiRestCall_402656044
proc url_UpdateDatasetGroup_402656869(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDatasetGroup_402656868(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Replaces the datasets in a dataset group with the specified datasets.</p> <note> <p>The <code>Status</code> of the dataset group must be <code>ACTIVE</code> before you can use the dataset group to create a predictor. Use the <a>DescribeDatasetGroup</a> operation to get the status.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656870 = header.getOrDefault("X-Amz-Target")
  valid_402656870 = validateParameter(valid_402656870, JString, required = true, default = newJString(
      "AmazonForecast.UpdateDatasetGroup"))
  if valid_402656870 != nil:
    section.add "X-Amz-Target", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Security-Token", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Signature")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Signature", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Algorithm", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Date")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Date", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Credential")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Credential", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656879: Call_UpdateDatasetGroup_402656867;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Replaces the datasets in a dataset group with the specified datasets.</p> <note> <p>The <code>Status</code> of the dataset group must be <code>ACTIVE</code> before you can use the dataset group to create a predictor. Use the <a>DescribeDatasetGroup</a> operation to get the status.</p> </note>
                                                                                         ## 
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_UpdateDatasetGroup_402656867; body: JsonNode): Recallable =
  ## updateDatasetGroup
  ## <p>Replaces the datasets in a dataset group with the specified datasets.</p> <note> <p>The <code>Status</code> of the dataset group must be <code>ACTIVE</code> before you can use the dataset group to create a predictor. Use the <a>DescribeDatasetGroup</a> operation to get the status.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656881 = newJObject()
  if body != nil:
    body_402656881 = body
  result = call_402656880.call(nil, nil, nil, nil, body_402656881)

var updateDatasetGroup* = Call_UpdateDatasetGroup_402656867(
    name: "updateDatasetGroup", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.UpdateDatasetGroup",
    validator: validate_UpdateDatasetGroup_402656868, base: "/",
    makeUrl: url_UpdateDatasetGroup_402656869,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}