
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
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
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "forecast.ap-northeast-1.amazonaws.com", "ap-southeast-1": "forecast.ap-southeast-1.amazonaws.com",
                           "us-west-2": "forecast.us-west-2.amazonaws.com",
                           "eu-west-2": "forecast.eu-west-2.amazonaws.com", "ap-northeast-3": "forecast.ap-northeast-3.amazonaws.com", "eu-central-1": "forecast.eu-central-1.amazonaws.com",
                           "us-east-2": "forecast.us-east-2.amazonaws.com",
                           "us-east-1": "forecast.us-east-1.amazonaws.com", "cn-northwest-1": "forecast.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "forecast.ap-south-1.amazonaws.com",
                           "eu-north-1": "forecast.eu-north-1.amazonaws.com", "ap-northeast-2": "forecast.ap-northeast-2.amazonaws.com",
                           "us-west-1": "forecast.us-west-1.amazonaws.com", "us-gov-east-1": "forecast.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "forecast.eu-west-3.amazonaws.com", "cn-north-1": "forecast.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "forecast.sa-east-1.amazonaws.com",
                           "eu-west-1": "forecast.eu-west-1.amazonaws.com", "us-gov-west-1": "forecast.us-gov-west-1.amazonaws.com", "ap-southeast-2": "forecast.ap-southeast-2.amazonaws.com", "ca-central-1": "forecast.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateDataset_601727 = ref object of OpenApiRestCall_601389
proc url_CreateDataset_601729(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataset_601728(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "AmazonForecast.CreateDataset"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_CreateDataset_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Forecast dataset. The information about the dataset that you provide helps Forecast understand how to consume the data for model training. This includes the following:</p> <ul> <li> <p> <i> <code>DataFrequency</code> </i> - How frequently your historical time-series data is collected.</p> </li> <li> <p> <i> <code>Domain</code> </i> and <i> <code>DatasetType</code> </i> - Each dataset has an associated dataset domain and a type within the domain. Amazon Forecast provides a list of predefined domains and types within each domain. For each unique dataset domain and type within the domain, Amazon Forecast requires your data to include a minimum set of predefined fields.</p> </li> <li> <p> <i> <code>Schema</code> </i> - A schema specifies the fields in the dataset, including the field name and data type.</p> </li> </ul> <p>After creating a dataset, you import your training data into it and add the dataset to a dataset group. You use the dataset group to create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets, use the <a>ListDatasets</a> operation.</p> <p>For example Forecast datasets, see the <a href="https://github.com/aws-samples/amazon-forecast-samples/tree/master/data">Amazon Forecast Sample GitHub repository</a>.</p> <note> <p>The <code>Status</code> of a dataset must be <code>ACTIVE</code> before you can import training data. Use the <a>DescribeDataset</a> operation to get the status.</p> </note>
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_CreateDataset_601727; body: JsonNode): Recallable =
  ## createDataset
  ## <p>Creates an Amazon Forecast dataset. The information about the dataset that you provide helps Forecast understand how to consume the data for model training. This includes the following:</p> <ul> <li> <p> <i> <code>DataFrequency</code> </i> - How frequently your historical time-series data is collected.</p> </li> <li> <p> <i> <code>Domain</code> </i> and <i> <code>DatasetType</code> </i> - Each dataset has an associated dataset domain and a type within the domain. Amazon Forecast provides a list of predefined domains and types within each domain. For each unique dataset domain and type within the domain, Amazon Forecast requires your data to include a minimum set of predefined fields.</p> </li> <li> <p> <i> <code>Schema</code> </i> - A schema specifies the fields in the dataset, including the field name and data type.</p> </li> </ul> <p>After creating a dataset, you import your training data into it and add the dataset to a dataset group. You use the dataset group to create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets, use the <a>ListDatasets</a> operation.</p> <p>For example Forecast datasets, see the <a href="https://github.com/aws-samples/amazon-forecast-samples/tree/master/data">Amazon Forecast Sample GitHub repository</a>.</p> <note> <p>The <code>Status</code> of a dataset must be <code>ACTIVE</code> before you can import training data. Use the <a>DescribeDataset</a> operation to get the status.</p> </note>
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var createDataset* = Call_CreateDataset_601727(name: "createDataset",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateDataset",
    validator: validate_CreateDataset_601728, base: "/", url: url_CreateDataset_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetGroup_601996 = ref object of OpenApiRestCall_601389
proc url_CreateDatasetGroup_601998(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatasetGroup_601997(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "AmazonForecast.CreateDatasetGroup"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_CreateDatasetGroup_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dataset group, which holds a collection of related datasets. You can add datasets to the dataset group when you create the dataset group, or later by using the <a>UpdateDatasetGroup</a> operation.</p> <p>After creating a dataset group and adding datasets, you use the dataset group when you create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets groups, use the <a>ListDatasetGroups</a> operation.</p> <note> <p>The <code>Status</code> of a dataset group must be <code>ACTIVE</code> before you can create use the dataset group to create a predictor. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> </note>
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_CreateDatasetGroup_601996; body: JsonNode): Recallable =
  ## createDatasetGroup
  ## <p>Creates a dataset group, which holds a collection of related datasets. You can add datasets to the dataset group when you create the dataset group, or later by using the <a>UpdateDatasetGroup</a> operation.</p> <p>After creating a dataset group and adding datasets, you use the dataset group when you create a predictor. For more information, see <a>howitworks-datasets-groups</a>.</p> <p>To get a list of all your datasets groups, use the <a>ListDatasetGroups</a> operation.</p> <note> <p>The <code>Status</code> of a dataset group must be <code>ACTIVE</code> before you can create use the dataset group to create a predictor. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> </note>
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var createDatasetGroup* = Call_CreateDatasetGroup_601996(
    name: "createDatasetGroup", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateDatasetGroup",
    validator: validate_CreateDatasetGroup_601997, base: "/",
    url: url_CreateDatasetGroup_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDatasetImportJob_602011 = ref object of OpenApiRestCall_601389
proc url_CreateDatasetImportJob_602013(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDatasetImportJob_602012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "AmazonForecast.CreateDatasetImportJob"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_CreateDatasetImportJob_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Imports your training data to an Amazon Forecast dataset. You provide the location of your training data in an Amazon Simple Storage Service (Amazon S3) bucket and the Amazon Resource Name (ARN) of the dataset that you want to import the data to.</p> <p>You must specify a <a>DataSource</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the data. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>The training data must be in CSV format. The delimiter must be a comma (,).</p> <p>You can specify the path to a specific CSV file, the S3 bucket, or to a folder in the S3 bucket. For the latter two cases, Amazon Forecast imports all files up to the limit of 10,000 files.</p> <p>To get a list of all your dataset import jobs, filtered by specified criteria, use the <a>ListDatasetImportJobs</a> operation.</p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_CreateDatasetImportJob_602011; body: JsonNode): Recallable =
  ## createDatasetImportJob
  ## <p>Imports your training data to an Amazon Forecast dataset. You provide the location of your training data in an Amazon Simple Storage Service (Amazon S3) bucket and the Amazon Resource Name (ARN) of the dataset that you want to import the data to.</p> <p>You must specify a <a>DataSource</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the data. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>The training data must be in CSV format. The delimiter must be a comma (,).</p> <p>You can specify the path to a specific CSV file, the S3 bucket, or to a folder in the S3 bucket. For the latter two cases, Amazon Forecast imports all files up to the limit of 10,000 files.</p> <p>To get a list of all your dataset import jobs, filtered by specified criteria, use the <a>ListDatasetImportJobs</a> operation.</p>
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var createDatasetImportJob* = Call_CreateDatasetImportJob_602011(
    name: "createDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateDatasetImportJob",
    validator: validate_CreateDatasetImportJob_602012, base: "/",
    url: url_CreateDatasetImportJob_602013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateForecast_602026 = ref object of OpenApiRestCall_601389
proc url_CreateForecast_602028(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateForecast_602027(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString(
      "AmazonForecast.CreateForecast"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CreateForecast_602026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a forecast for each item in the <code>TARGET_TIME_SERIES</code> dataset that was used to train the predictor. This is known as inference. To retrieve the forecast for a single item at low latency, use the operation. To export the complete forecast into your Amazon Simple Storage Service (Amazon S3) bucket, use the <a>CreateForecastExportJob</a> operation.</p> <p>The range of the forecast is determined by the <code>ForecastHorizon</code> value, which you specify in the <a>CreatePredictor</a> request, multiplied by the <code>DataFrequency</code> value, which you specify in the <a>CreateDataset</a> request. When you query a forecast, you can request a specific date range within the forecast.</p> <p>To get a list of all your forecasts, use the <a>ListForecasts</a> operation.</p> <note> <p>The forecasts generated by Amazon Forecast are in the same time zone as the dataset that was used to create the predictor.</p> </note> <p>For more information, see <a>howitworks-forecast</a>.</p> <note> <p>The <code>Status</code> of the forecast must be <code>ACTIVE</code> before you can query or export the forecast. Use the <a>DescribeForecast</a> operation to get the status.</p> </note>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateForecast_602026; body: JsonNode): Recallable =
  ## createForecast
  ## <p>Creates a forecast for each item in the <code>TARGET_TIME_SERIES</code> dataset that was used to train the predictor. This is known as inference. To retrieve the forecast for a single item at low latency, use the operation. To export the complete forecast into your Amazon Simple Storage Service (Amazon S3) bucket, use the <a>CreateForecastExportJob</a> operation.</p> <p>The range of the forecast is determined by the <code>ForecastHorizon</code> value, which you specify in the <a>CreatePredictor</a> request, multiplied by the <code>DataFrequency</code> value, which you specify in the <a>CreateDataset</a> request. When you query a forecast, you can request a specific date range within the forecast.</p> <p>To get a list of all your forecasts, use the <a>ListForecasts</a> operation.</p> <note> <p>The forecasts generated by Amazon Forecast are in the same time zone as the dataset that was used to create the predictor.</p> </note> <p>For more information, see <a>howitworks-forecast</a>.</p> <note> <p>The <code>Status</code> of the forecast must be <code>ACTIVE</code> before you can query or export the forecast. Use the <a>DescribeForecast</a> operation to get the status.</p> </note>
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var createForecast* = Call_CreateForecast_602026(name: "createForecast",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateForecast",
    validator: validate_CreateForecast_602027, base: "/", url: url_CreateForecast_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateForecastExportJob_602041 = ref object of OpenApiRestCall_601389
proc url_CreateForecastExportJob_602043(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateForecastExportJob_602042(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "AmazonForecast.CreateForecastExportJob"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_CreateForecastExportJob_602041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports a forecast created by the <a>CreateForecast</a> operation to your Amazon Simple Storage Service (Amazon S3) bucket. The forecast file name will match the following conventions:</p> <p>&lt;ForecastExportJobName&gt;_&lt;ExportTimestamp&gt;_&lt;PageNumber&gt;</p> <p>where the &lt;ExportTimestamp&gt; component is in Java SimpleDateFormat (yyyy-MM-ddTHH-mm-ssZ).</p> <p>You must specify a <a>DataDestination</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>For more information, see <a>howitworks-forecast</a>.</p> <p>To get a list of all your forecast export jobs, use the <a>ListForecastExportJobs</a> operation.</p> <note> <p>The <code>Status</code> of the forecast export job must be <code>ACTIVE</code> before you can access the forecast in your Amazon S3 bucket. To get the status, use the <a>DescribeForecastExportJob</a> operation.</p> </note>
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_CreateForecastExportJob_602041; body: JsonNode): Recallable =
  ## createForecastExportJob
  ## <p>Exports a forecast created by the <a>CreateForecast</a> operation to your Amazon Simple Storage Service (Amazon S3) bucket. The forecast file name will match the following conventions:</p> <p>&lt;ForecastExportJobName&gt;_&lt;ExportTimestamp&gt;_&lt;PageNumber&gt;</p> <p>where the &lt;ExportTimestamp&gt; component is in Java SimpleDateFormat (yyyy-MM-ddTHH-mm-ssZ).</p> <p>You must specify a <a>DataDestination</a> object that includes an AWS Identity and Access Management (IAM) role that Amazon Forecast can assume to access the Amazon S3 bucket. For more information, see <a>aws-forecast-iam-roles</a>.</p> <p>For more information, see <a>howitworks-forecast</a>.</p> <p>To get a list of all your forecast export jobs, use the <a>ListForecastExportJobs</a> operation.</p> <note> <p>The <code>Status</code> of the forecast export job must be <code>ACTIVE</code> before you can access the forecast in your Amazon S3 bucket. To get the status, use the <a>DescribeForecastExportJob</a> operation.</p> </note>
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var createForecastExportJob* = Call_CreateForecastExportJob_602041(
    name: "createForecastExportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreateForecastExportJob",
    validator: validate_CreateForecastExportJob_602042, base: "/",
    url: url_CreateForecastExportJob_602043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePredictor_602056 = ref object of OpenApiRestCall_601389
proc url_CreatePredictor_602058(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePredictor_602057(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "AmazonForecast.CreatePredictor"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_CreatePredictor_602056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Forecast predictor.</p> <p>In the request, you provide a dataset group and either specify an algorithm or let Amazon Forecast choose the algorithm for you using AutoML. If you specify an algorithm, you also can override algorithm-specific hyperparameters.</p> <p>Amazon Forecast uses the chosen algorithm to train a model using the latest version of the datasets in the specified dataset group. The result is called a predictor. You then generate a forecast using the <a>CreateForecast</a> operation.</p> <p>After training a model, the <code>CreatePredictor</code> operation also evaluates it. To see the evaluation metrics, use the <a>GetAccuracyMetrics</a> operation. Always review the evaluation metrics before deciding to use the predictor to generate a forecast.</p> <p>Optionally, you can specify a featurization configuration to fill and aggregate the data fields in the <code>TARGET_TIME_SERIES</code> dataset to improve model training. For more information, see <a>FeaturizationConfig</a>.</p> <p>For RELATED_TIME_SERIES datasets, <code>CreatePredictor</code> verifies that the <code>DataFrequency</code> specified when the dataset was created matches the <code>ForecastFrequency</code>. TARGET_TIME_SERIES datasets don't have this restriction. Amazon Forecast also verifies the delimiter and timestamp format. For more information, see <a>howitworks-datasets-groups</a>.</p> <p> <b>AutoML</b> </p> <p>If you want Amazon Forecast to evaluate each algorithm and choose the one that minimizes the <code>objective function</code>, set <code>PerformAutoML</code> to <code>true</code>. The <code>objective function</code> is defined as the mean of the weighted p10, p50, and p90 quantile losses. For more information, see <a>EvaluationResult</a>.</p> <p>When AutoML is enabled, the following properties are disallowed:</p> <ul> <li> <p> <code>AlgorithmArn</code> </p> </li> <li> <p> <code>HPOConfig</code> </p> </li> <li> <p> <code>PerformHPO</code> </p> </li> <li> <p> <code>TrainingParameters</code> </p> </li> </ul> <p>To get a list of all of your predictors, use the <a>ListPredictors</a> operation.</p> <note> <p>Before you can use the predictor to create a forecast, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_CreatePredictor_602056; body: JsonNode): Recallable =
  ## createPredictor
  ## <p>Creates an Amazon Forecast predictor.</p> <p>In the request, you provide a dataset group and either specify an algorithm or let Amazon Forecast choose the algorithm for you using AutoML. If you specify an algorithm, you also can override algorithm-specific hyperparameters.</p> <p>Amazon Forecast uses the chosen algorithm to train a model using the latest version of the datasets in the specified dataset group. The result is called a predictor. You then generate a forecast using the <a>CreateForecast</a> operation.</p> <p>After training a model, the <code>CreatePredictor</code> operation also evaluates it. To see the evaluation metrics, use the <a>GetAccuracyMetrics</a> operation. Always review the evaluation metrics before deciding to use the predictor to generate a forecast.</p> <p>Optionally, you can specify a featurization configuration to fill and aggregate the data fields in the <code>TARGET_TIME_SERIES</code> dataset to improve model training. For more information, see <a>FeaturizationConfig</a>.</p> <p>For RELATED_TIME_SERIES datasets, <code>CreatePredictor</code> verifies that the <code>DataFrequency</code> specified when the dataset was created matches the <code>ForecastFrequency</code>. TARGET_TIME_SERIES datasets don't have this restriction. Amazon Forecast also verifies the delimiter and timestamp format. For more information, see <a>howitworks-datasets-groups</a>.</p> <p> <b>AutoML</b> </p> <p>If you want Amazon Forecast to evaluate each algorithm and choose the one that minimizes the <code>objective function</code>, set <code>PerformAutoML</code> to <code>true</code>. The <code>objective function</code> is defined as the mean of the weighted p10, p50, and p90 quantile losses. For more information, see <a>EvaluationResult</a>.</p> <p>When AutoML is enabled, the following properties are disallowed:</p> <ul> <li> <p> <code>AlgorithmArn</code> </p> </li> <li> <p> <code>HPOConfig</code> </p> </li> <li> <p> <code>PerformHPO</code> </p> </li> <li> <p> <code>TrainingParameters</code> </p> </li> </ul> <p>To get a list of all of your predictors, use the <a>ListPredictors</a> operation.</p> <note> <p>Before you can use the predictor to create a forecast, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var createPredictor* = Call_CreatePredictor_602056(name: "createPredictor",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.CreatePredictor",
    validator: validate_CreatePredictor_602057, base: "/", url: url_CreatePredictor_602058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataset_602071 = ref object of OpenApiRestCall_601389
proc url_DeleteDataset_602073(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDataset_602072(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "AmazonForecast.DeleteDataset"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_DeleteDataset_602071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon Forecast dataset that was created using the <a>CreateDataset</a> operation. You can only delete datasets that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status use the <a>DescribeDataset</a> operation.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DeleteDataset_602071; body: JsonNode): Recallable =
  ## deleteDataset
  ## Deletes an Amazon Forecast dataset that was created using the <a>CreateDataset</a> operation. You can only delete datasets that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status use the <a>DescribeDataset</a> operation.
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var deleteDataset* = Call_DeleteDataset_602071(name: "deleteDataset",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteDataset",
    validator: validate_DeleteDataset_602072, base: "/", url: url_DeleteDataset_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetGroup_602086 = ref object of OpenApiRestCall_601389
proc url_DeleteDatasetGroup_602088(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDatasetGroup_602087(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "AmazonForecast.DeleteDatasetGroup"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_DeleteDatasetGroup_602086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a dataset group created using the <a>CreateDatasetGroup</a> operation. You can only delete dataset groups that have a status of <code>ACTIVE</code>, <code>CREATE_FAILED</code>, or <code>UPDATE_FAILED</code>. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> <p>This operation deletes only the dataset group, not the datasets in the group.</p>
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_DeleteDatasetGroup_602086; body: JsonNode): Recallable =
  ## deleteDatasetGroup
  ## <p>Deletes a dataset group created using the <a>CreateDatasetGroup</a> operation. You can only delete dataset groups that have a status of <code>ACTIVE</code>, <code>CREATE_FAILED</code>, or <code>UPDATE_FAILED</code>. To get the status, use the <a>DescribeDatasetGroup</a> operation.</p> <p>This operation deletes only the dataset group, not the datasets in the group.</p>
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var deleteDatasetGroup* = Call_DeleteDatasetGroup_602086(
    name: "deleteDatasetGroup", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteDatasetGroup",
    validator: validate_DeleteDatasetGroup_602087, base: "/",
    url: url_DeleteDatasetGroup_602088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDatasetImportJob_602101 = ref object of OpenApiRestCall_601389
proc url_DeleteDatasetImportJob_602103(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDatasetImportJob_602102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "AmazonForecast.DeleteDatasetImportJob"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_DeleteDatasetImportJob_602101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataset import job created using the <a>CreateDatasetImportJob</a> operation. You can delete only dataset import jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeDatasetImportJob</a> operation.
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_DeleteDatasetImportJob_602101; body: JsonNode): Recallable =
  ## deleteDatasetImportJob
  ## Deletes a dataset import job created using the <a>CreateDatasetImportJob</a> operation. You can delete only dataset import jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeDatasetImportJob</a> operation.
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var deleteDatasetImportJob* = Call_DeleteDatasetImportJob_602101(
    name: "deleteDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteDatasetImportJob",
    validator: validate_DeleteDatasetImportJob_602102, base: "/",
    url: url_DeleteDatasetImportJob_602103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteForecast_602116 = ref object of OpenApiRestCall_601389
proc url_DeleteForecast_602118(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteForecast_602117(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602119 = header.getOrDefault("X-Amz-Target")
  valid_602119 = validateParameter(valid_602119, JString, required = true, default = newJString(
      "AmazonForecast.DeleteForecast"))
  if valid_602119 != nil:
    section.add "X-Amz-Target", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_DeleteForecast_602116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a forecast created using the <a>CreateForecast</a> operation. You can delete only forecasts that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecast</a> operation.</p> <p>You can't delete a forecast while it is being exported. After a forecast is deleted, you can no longer query the forecast.</p>
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_DeleteForecast_602116; body: JsonNode): Recallable =
  ## deleteForecast
  ## <p>Deletes a forecast created using the <a>CreateForecast</a> operation. You can delete only forecasts that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecast</a> operation.</p> <p>You can't delete a forecast while it is being exported. After a forecast is deleted, you can no longer query the forecast.</p>
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var deleteForecast* = Call_DeleteForecast_602116(name: "deleteForecast",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteForecast",
    validator: validate_DeleteForecast_602117, base: "/", url: url_DeleteForecast_602118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteForecastExportJob_602131 = ref object of OpenApiRestCall_601389
proc url_DeleteForecastExportJob_602133(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteForecastExportJob_602132(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602134 = header.getOrDefault("X-Amz-Target")
  valid_602134 = validateParameter(valid_602134, JString, required = true, default = newJString(
      "AmazonForecast.DeleteForecastExportJob"))
  if valid_602134 != nil:
    section.add "X-Amz-Target", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_DeleteForecastExportJob_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a forecast export job created using the <a>CreateForecastExportJob</a> operation. You can delete only export jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecastExportJob</a> operation.
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_DeleteForecastExportJob_602131; body: JsonNode): Recallable =
  ## deleteForecastExportJob
  ## Deletes a forecast export job created using the <a>CreateForecastExportJob</a> operation. You can delete only export jobs that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribeForecastExportJob</a> operation.
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var deleteForecastExportJob* = Call_DeleteForecastExportJob_602131(
    name: "deleteForecastExportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeleteForecastExportJob",
    validator: validate_DeleteForecastExportJob_602132, base: "/",
    url: url_DeleteForecastExportJob_602133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePredictor_602146 = ref object of OpenApiRestCall_601389
proc url_DeletePredictor_602148(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePredictor_602147(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602149 = header.getOrDefault("X-Amz-Target")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "AmazonForecast.DeletePredictor"))
  if valid_602149 != nil:
    section.add "X-Amz-Target", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_DeletePredictor_602146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a predictor created using the <a>CreatePredictor</a> operation. You can delete only predictor that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribePredictor</a> operation.
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_DeletePredictor_602146; body: JsonNode): Recallable =
  ## deletePredictor
  ## Deletes a predictor created using the <a>CreatePredictor</a> operation. You can delete only predictor that have a status of <code>ACTIVE</code> or <code>CREATE_FAILED</code>. To get the status, use the <a>DescribePredictor</a> operation.
  ##   body: JObject (required)
  var body_602160 = newJObject()
  if body != nil:
    body_602160 = body
  result = call_602159.call(nil, nil, nil, nil, body_602160)

var deletePredictor* = Call_DeletePredictor_602146(name: "deletePredictor",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DeletePredictor",
    validator: validate_DeletePredictor_602147, base: "/", url: url_DeletePredictor_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataset_602161 = ref object of OpenApiRestCall_601389
proc url_DescribeDataset_602163(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDataset_602162(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602164 = header.getOrDefault("X-Amz-Target")
  valid_602164 = validateParameter(valid_602164, JString, required = true, default = newJString(
      "AmazonForecast.DescribeDataset"))
  if valid_602164 != nil:
    section.add "X-Amz-Target", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Signature")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Signature", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Content-Sha256", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Date")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Date", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Security-Token")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Security-Token", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Algorithm")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Algorithm", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-SignedHeaders", valid_602171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602173: Call_DescribeDataset_602161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an Amazon Forecast dataset created using the <a>CreateDataset</a> operation.</p> <p>In addition to listing the parameters specified in the <code>CreateDataset</code> request, this operation includes the following dataset properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602173, url, valid)

proc call*(call_602174: Call_DescribeDataset_602161; body: JsonNode): Recallable =
  ## describeDataset
  ## <p>Describes an Amazon Forecast dataset created using the <a>CreateDataset</a> operation.</p> <p>In addition to listing the parameters specified in the <code>CreateDataset</code> request, this operation includes the following dataset properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
  ##   body: JObject (required)
  var body_602175 = newJObject()
  if body != nil:
    body_602175 = body
  result = call_602174.call(nil, nil, nil, nil, body_602175)

var describeDataset* = Call_DescribeDataset_602161(name: "describeDataset",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeDataset",
    validator: validate_DescribeDataset_602162, base: "/", url: url_DescribeDataset_602163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatasetGroup_602176 = ref object of OpenApiRestCall_601389
proc url_DescribeDatasetGroup_602178(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDatasetGroup_602177(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602179 = header.getOrDefault("X-Amz-Target")
  valid_602179 = validateParameter(valid_602179, JString, required = true, default = newJString(
      "AmazonForecast.DescribeDatasetGroup"))
  if valid_602179 != nil:
    section.add "X-Amz-Target", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Signature")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Signature", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Content-Sha256", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Date")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Date", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_DescribeDatasetGroup_602176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a dataset group created using the <a>CreateDatasetGroup</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetGroup</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>DatasetArns</code> - The datasets belonging to the group.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_DescribeDatasetGroup_602176; body: JsonNode): Recallable =
  ## describeDatasetGroup
  ## <p>Describes a dataset group created using the <a>CreateDatasetGroup</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetGroup</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>DatasetArns</code> - The datasets belonging to the group.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> </ul>
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var describeDatasetGroup* = Call_DescribeDatasetGroup_602176(
    name: "describeDatasetGroup", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeDatasetGroup",
    validator: validate_DescribeDatasetGroup_602177, base: "/",
    url: url_DescribeDatasetGroup_602178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDatasetImportJob_602191 = ref object of OpenApiRestCall_601389
proc url_DescribeDatasetImportJob_602193(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDatasetImportJob_602192(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602194 = header.getOrDefault("X-Amz-Target")
  valid_602194 = validateParameter(valid_602194, JString, required = true, default = newJString(
      "AmazonForecast.DescribeDatasetImportJob"))
  if valid_602194 != nil:
    section.add "X-Amz-Target", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Signature")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Signature", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Content-Sha256", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Date")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Date", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Security-Token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Security-Token", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Algorithm")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Algorithm", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_DescribeDatasetImportJob_602191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a dataset import job created using the <a>CreateDatasetImportJob</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetImportJob</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>DataSize</code> </p> </li> <li> <p> <code>FieldStatistics</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_DescribeDatasetImportJob_602191; body: JsonNode): Recallable =
  ## describeDatasetImportJob
  ## <p>Describes a dataset import job created using the <a>CreateDatasetImportJob</a> operation.</p> <p>In addition to listing the parameters provided in the <code>CreateDatasetImportJob</code> request, this operation includes the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>DataSize</code> </p> </li> <li> <p> <code>FieldStatistics</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602205 = newJObject()
  if body != nil:
    body_602205 = body
  result = call_602204.call(nil, nil, nil, nil, body_602205)

var describeDatasetImportJob* = Call_DescribeDatasetImportJob_602191(
    name: "describeDatasetImportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeDatasetImportJob",
    validator: validate_DescribeDatasetImportJob_602192, base: "/",
    url: url_DescribeDatasetImportJob_602193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeForecast_602206 = ref object of OpenApiRestCall_601389
proc url_DescribeForecast_602208(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeForecast_602207(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602209 = header.getOrDefault("X-Amz-Target")
  valid_602209 = validateParameter(valid_602209, JString, required = true, default = newJString(
      "AmazonForecast.DescribeForecast"))
  if valid_602209 != nil:
    section.add "X-Amz-Target", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Signature")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Signature", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Date")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Date", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Credential")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Credential", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Security-Token")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Security-Token", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Algorithm")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Algorithm", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_DescribeForecast_602206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a forecast created using the <a>CreateForecast</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreateForecast</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetGroupArn</code> - The dataset group that provided the training data.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_DescribeForecast_602206; body: JsonNode): Recallable =
  ## describeForecast
  ## <p>Describes a forecast created using the <a>CreateForecast</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreateForecast</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetGroupArn</code> - The dataset group that provided the training data.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602220 = newJObject()
  if body != nil:
    body_602220 = body
  result = call_602219.call(nil, nil, nil, nil, body_602220)

var describeForecast* = Call_DescribeForecast_602206(name: "describeForecast",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeForecast",
    validator: validate_DescribeForecast_602207, base: "/",
    url: url_DescribeForecast_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeForecastExportJob_602221 = ref object of OpenApiRestCall_601389
proc url_DescribeForecastExportJob_602223(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeForecastExportJob_602222(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602224 = header.getOrDefault("X-Amz-Target")
  valid_602224 = validateParameter(valid_602224, JString, required = true, default = newJString(
      "AmazonForecast.DescribeForecastExportJob"))
  if valid_602224 != nil:
    section.add "X-Amz-Target", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_DescribeForecastExportJob_602221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a forecast export job created using the <a>CreateForecastExportJob</a> operation.</p> <p>In addition to listing the properties provided by the user in the <code>CreateForecastExportJob</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_DescribeForecastExportJob_602221; body: JsonNode): Recallable =
  ## describeForecastExportJob
  ## <p>Describes a forecast export job created using the <a>CreateForecastExportJob</a> operation.</p> <p>In addition to listing the properties provided by the user in the <code>CreateForecastExportJob</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602235 = newJObject()
  if body != nil:
    body_602235 = body
  result = call_602234.call(nil, nil, nil, nil, body_602235)

var describeForecastExportJob* = Call_DescribeForecastExportJob_602221(
    name: "describeForecastExportJob", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribeForecastExportJob",
    validator: validate_DescribeForecastExportJob_602222, base: "/",
    url: url_DescribeForecastExportJob_602223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePredictor_602236 = ref object of OpenApiRestCall_601389
proc url_DescribePredictor_602238(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePredictor_602237(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602239 = header.getOrDefault("X-Amz-Target")
  valid_602239 = validateParameter(valid_602239, JString, required = true, default = newJString(
      "AmazonForecast.DescribePredictor"))
  if valid_602239 != nil:
    section.add "X-Amz-Target", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602248: Call_DescribePredictor_602236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a predictor created using the <a>CreatePredictor</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreatePredictor</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetImportJobArns</code> - The dataset import jobs used to import training data.</p> </li> <li> <p> <code>AutoMLAlgorithmArns</code> - If AutoML is performed, the algorithms that were evaluated.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_DescribePredictor_602236; body: JsonNode): Recallable =
  ## describePredictor
  ## <p>Describes a predictor created using the <a>CreatePredictor</a> operation.</p> <p>In addition to listing the properties provided in the <code>CreatePredictor</code> request, this operation lists the following properties:</p> <ul> <li> <p> <code>DatasetImportJobArns</code> - The dataset import jobs used to import training data.</p> </li> <li> <p> <code>AutoMLAlgorithmArns</code> - If AutoML is performed, the algorithms that were evaluated.</p> </li> <li> <p> <code>CreationTime</code> </p> </li> <li> <p> <code>LastModificationTime</code> </p> </li> <li> <p> <code>Status</code> </p> </li> <li> <p> <code>Message</code> - If an error occurred, information about the error.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602250 = newJObject()
  if body != nil:
    body_602250 = body
  result = call_602249.call(nil, nil, nil, nil, body_602250)

var describePredictor* = Call_DescribePredictor_602236(name: "describePredictor",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.DescribePredictor",
    validator: validate_DescribePredictor_602237, base: "/",
    url: url_DescribePredictor_602238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccuracyMetrics_602251 = ref object of OpenApiRestCall_601389
proc url_GetAccuracyMetrics_602253(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccuracyMetrics_602252(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602254 = header.getOrDefault("X-Amz-Target")
  valid_602254 = validateParameter(valid_602254, JString, required = true, default = newJString(
      "AmazonForecast.GetAccuracyMetrics"))
  if valid_602254 != nil:
    section.add "X-Amz-Target", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Signature")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Signature", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Content-Sha256", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Date")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Date", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Credential")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Credential", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_GetAccuracyMetrics_602251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides metrics on the accuracy of the models that were trained by the <a>CreatePredictor</a> operation. Use metrics to see how well the model performed and to decide whether to use the predictor to generate a forecast. For more information, see <a>metrics</a>.</p> <p>This operation generates metrics for each backtest window that was evaluated. The number of backtest windows (<code>NumberOfBacktestWindows</code>) is specified using the <a>EvaluationParameters</a> object, which is optionally included in the <code>CreatePredictor</code> request. If <code>NumberOfBacktestWindows</code> isn't specified, the number defaults to one.</p> <p>The parameters of the <code>filling</code> method determine which items contribute to the metrics. If you want all items to contribute, specify <code>zero</code>. If you want only those items that have complete data in the range being evaluated to contribute, specify <code>nan</code>. For more information, see <a>FeaturizationMethod</a>.</p> <note> <p>Before you can get accuracy metrics, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_GetAccuracyMetrics_602251; body: JsonNode): Recallable =
  ## getAccuracyMetrics
  ## <p>Provides metrics on the accuracy of the models that were trained by the <a>CreatePredictor</a> operation. Use metrics to see how well the model performed and to decide whether to use the predictor to generate a forecast. For more information, see <a>metrics</a>.</p> <p>This operation generates metrics for each backtest window that was evaluated. The number of backtest windows (<code>NumberOfBacktestWindows</code>) is specified using the <a>EvaluationParameters</a> object, which is optionally included in the <code>CreatePredictor</code> request. If <code>NumberOfBacktestWindows</code> isn't specified, the number defaults to one.</p> <p>The parameters of the <code>filling</code> method determine which items contribute to the metrics. If you want all items to contribute, specify <code>zero</code>. If you want only those items that have complete data in the range being evaluated to contribute, specify <code>nan</code>. For more information, see <a>FeaturizationMethod</a>.</p> <note> <p>Before you can get accuracy metrics, the <code>Status</code> of the predictor must be <code>ACTIVE</code>, signifying that training has completed. To get the status, use the <a>DescribePredictor</a> operation.</p> </note>
  ##   body: JObject (required)
  var body_602265 = newJObject()
  if body != nil:
    body_602265 = body
  result = call_602264.call(nil, nil, nil, nil, body_602265)

var getAccuracyMetrics* = Call_GetAccuracyMetrics_602251(
    name: "getAccuracyMetrics", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.GetAccuracyMetrics",
    validator: validate_GetAccuracyMetrics_602252, base: "/",
    url: url_GetAccuracyMetrics_602253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetGroups_602266 = ref object of OpenApiRestCall_601389
proc url_ListDatasetGroups_602268(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasetGroups_602267(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_602269 = query.getOrDefault("MaxResults")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "MaxResults", valid_602269
  var valid_602270 = query.getOrDefault("NextToken")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "NextToken", valid_602270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602271 = header.getOrDefault("X-Amz-Target")
  valid_602271 = validateParameter(valid_602271, JString, required = true, default = newJString(
      "AmazonForecast.ListDatasetGroups"))
  if valid_602271 != nil:
    section.add "X-Amz-Target", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Signature")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Signature", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Content-Sha256", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Date")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Date", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Credential")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Credential", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Security-Token")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Security-Token", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Algorithm")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Algorithm", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-SignedHeaders", valid_602278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602280: Call_ListDatasetGroups_602266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of dataset groups created using the <a>CreateDatasetGroup</a> operation. For each dataset group, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the dataset group ARN with the <a>DescribeDatasetGroup</a> operation.
  ## 
  let valid = call_602280.validator(path, query, header, formData, body)
  let scheme = call_602280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602280.url(scheme.get, call_602280.host, call_602280.base,
                         call_602280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602280, url, valid)

proc call*(call_602281: Call_ListDatasetGroups_602266; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDatasetGroups
  ## Returns a list of dataset groups created using the <a>CreateDatasetGroup</a> operation. For each dataset group, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the dataset group ARN with the <a>DescribeDatasetGroup</a> operation.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602282 = newJObject()
  var body_602283 = newJObject()
  add(query_602282, "MaxResults", newJString(MaxResults))
  add(query_602282, "NextToken", newJString(NextToken))
  if body != nil:
    body_602283 = body
  result = call_602281.call(nil, query_602282, nil, nil, body_602283)

var listDatasetGroups* = Call_ListDatasetGroups_602266(name: "listDatasetGroups",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListDatasetGroups",
    validator: validate_ListDatasetGroups_602267, base: "/",
    url: url_ListDatasetGroups_602268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasetImportJobs_602285 = ref object of OpenApiRestCall_601389
proc url_ListDatasetImportJobs_602287(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasetImportJobs_602286(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602288 = query.getOrDefault("MaxResults")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "MaxResults", valid_602288
  var valid_602289 = query.getOrDefault("NextToken")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "NextToken", valid_602289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602290 = header.getOrDefault("X-Amz-Target")
  valid_602290 = validateParameter(valid_602290, JString, required = true, default = newJString(
      "AmazonForecast.ListDatasetImportJobs"))
  if valid_602290 != nil:
    section.add "X-Amz-Target", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Signature")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Signature", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Content-Sha256", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Date")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Date", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Credential")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Credential", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Security-Token")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Security-Token", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Algorithm")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Algorithm", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-SignedHeaders", valid_602297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602299: Call_ListDatasetImportJobs_602285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of dataset import jobs created using the <a>CreateDatasetImportJob</a> operation. For each import job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribeDatasetImportJob</a> operation. You can filter the list by providing an array of <a>Filter</a> objects.
  ## 
  let valid = call_602299.validator(path, query, header, formData, body)
  let scheme = call_602299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602299.url(scheme.get, call_602299.host, call_602299.base,
                         call_602299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602299, url, valid)

proc call*(call_602300: Call_ListDatasetImportJobs_602285; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDatasetImportJobs
  ## Returns a list of dataset import jobs created using the <a>CreateDatasetImportJob</a> operation. For each import job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribeDatasetImportJob</a> operation. You can filter the list by providing an array of <a>Filter</a> objects.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602301 = newJObject()
  var body_602302 = newJObject()
  add(query_602301, "MaxResults", newJString(MaxResults))
  add(query_602301, "NextToken", newJString(NextToken))
  if body != nil:
    body_602302 = body
  result = call_602300.call(nil, query_602301, nil, nil, body_602302)

var listDatasetImportJobs* = Call_ListDatasetImportJobs_602285(
    name: "listDatasetImportJobs", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListDatasetImportJobs",
    validator: validate_ListDatasetImportJobs_602286, base: "/",
    url: url_ListDatasetImportJobs_602287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDatasets_602303 = ref object of OpenApiRestCall_601389
proc url_ListDatasets_602305(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDatasets_602304(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602306 = query.getOrDefault("MaxResults")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "MaxResults", valid_602306
  var valid_602307 = query.getOrDefault("NextToken")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "NextToken", valid_602307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602308 = header.getOrDefault("X-Amz-Target")
  valid_602308 = validateParameter(valid_602308, JString, required = true, default = newJString(
      "AmazonForecast.ListDatasets"))
  if valid_602308 != nil:
    section.add "X-Amz-Target", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Signature")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Signature", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Content-Sha256", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Date")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Date", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Credential")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Credential", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Security-Token")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Security-Token", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Algorithm")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Algorithm", valid_602314
  var valid_602315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-SignedHeaders", valid_602315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602317: Call_ListDatasets_602303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of datasets created using the <a>CreateDataset</a> operation. For each dataset, a summary of its properties, including its Amazon Resource Name (ARN), is returned. To retrieve the complete set of properties, use the ARN with the <a>DescribeDataset</a> operation.
  ## 
  let valid = call_602317.validator(path, query, header, formData, body)
  let scheme = call_602317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602317.url(scheme.get, call_602317.host, call_602317.base,
                         call_602317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602317, url, valid)

proc call*(call_602318: Call_ListDatasets_602303; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDatasets
  ## Returns a list of datasets created using the <a>CreateDataset</a> operation. For each dataset, a summary of its properties, including its Amazon Resource Name (ARN), is returned. To retrieve the complete set of properties, use the ARN with the <a>DescribeDataset</a> operation.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602319 = newJObject()
  var body_602320 = newJObject()
  add(query_602319, "MaxResults", newJString(MaxResults))
  add(query_602319, "NextToken", newJString(NextToken))
  if body != nil:
    body_602320 = body
  result = call_602318.call(nil, query_602319, nil, nil, body_602320)

var listDatasets* = Call_ListDatasets_602303(name: "listDatasets",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListDatasets",
    validator: validate_ListDatasets_602304, base: "/", url: url_ListDatasets_602305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListForecastExportJobs_602321 = ref object of OpenApiRestCall_601389
proc url_ListForecastExportJobs_602323(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListForecastExportJobs_602322(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602324 = query.getOrDefault("MaxResults")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "MaxResults", valid_602324
  var valid_602325 = query.getOrDefault("NextToken")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "NextToken", valid_602325
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602326 = header.getOrDefault("X-Amz-Target")
  valid_602326 = validateParameter(valid_602326, JString, required = true, default = newJString(
      "AmazonForecast.ListForecastExportJobs"))
  if valid_602326 != nil:
    section.add "X-Amz-Target", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Signature")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Signature", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Content-Sha256", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Date")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Date", valid_602329
  var valid_602330 = header.getOrDefault("X-Amz-Credential")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Credential", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Security-Token")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Security-Token", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Algorithm")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Algorithm", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-SignedHeaders", valid_602333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602335: Call_ListForecastExportJobs_602321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of forecast export jobs created using the <a>CreateForecastExportJob</a> operation. For each forecast export job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, use the ARN with the <a>DescribeForecastExportJob</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ## 
  let valid = call_602335.validator(path, query, header, formData, body)
  let scheme = call_602335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602335.url(scheme.get, call_602335.host, call_602335.base,
                         call_602335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602335, url, valid)

proc call*(call_602336: Call_ListForecastExportJobs_602321; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listForecastExportJobs
  ## Returns a list of forecast export jobs created using the <a>CreateForecastExportJob</a> operation. For each forecast export job, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, use the ARN with the <a>DescribeForecastExportJob</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602337 = newJObject()
  var body_602338 = newJObject()
  add(query_602337, "MaxResults", newJString(MaxResults))
  add(query_602337, "NextToken", newJString(NextToken))
  if body != nil:
    body_602338 = body
  result = call_602336.call(nil, query_602337, nil, nil, body_602338)

var listForecastExportJobs* = Call_ListForecastExportJobs_602321(
    name: "listForecastExportJobs", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListForecastExportJobs",
    validator: validate_ListForecastExportJobs_602322, base: "/",
    url: url_ListForecastExportJobs_602323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListForecasts_602339 = ref object of OpenApiRestCall_601389
proc url_ListForecasts_602341(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListForecasts_602340(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602342 = query.getOrDefault("MaxResults")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "MaxResults", valid_602342
  var valid_602343 = query.getOrDefault("NextToken")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "NextToken", valid_602343
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602344 = header.getOrDefault("X-Amz-Target")
  valid_602344 = validateParameter(valid_602344, JString, required = true, default = newJString(
      "AmazonForecast.ListForecasts"))
  if valid_602344 != nil:
    section.add "X-Amz-Target", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Signature")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Signature", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Content-Sha256", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Date")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Date", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Credential")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Credential", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Security-Token")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Security-Token", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Algorithm")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Algorithm", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-SignedHeaders", valid_602351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602353: Call_ListForecasts_602339; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of forecasts created using the <a>CreateForecast</a> operation. For each forecast, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, specify the ARN with the <a>DescribeForecast</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ## 
  let valid = call_602353.validator(path, query, header, formData, body)
  let scheme = call_602353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602353.url(scheme.get, call_602353.host, call_602353.base,
                         call_602353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602353, url, valid)

proc call*(call_602354: Call_ListForecasts_602339; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listForecasts
  ## Returns a list of forecasts created using the <a>CreateForecast</a> operation. For each forecast, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). To retrieve the complete set of properties, specify the ARN with the <a>DescribeForecast</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602355 = newJObject()
  var body_602356 = newJObject()
  add(query_602355, "MaxResults", newJString(MaxResults))
  add(query_602355, "NextToken", newJString(NextToken))
  if body != nil:
    body_602356 = body
  result = call_602354.call(nil, query_602355, nil, nil, body_602356)

var listForecasts* = Call_ListForecasts_602339(name: "listForecasts",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListForecasts",
    validator: validate_ListForecasts_602340, base: "/", url: url_ListForecasts_602341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPredictors_602357 = ref object of OpenApiRestCall_601389
proc url_ListPredictors_602359(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPredictors_602358(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_602360 = query.getOrDefault("MaxResults")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "MaxResults", valid_602360
  var valid_602361 = query.getOrDefault("NextToken")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "NextToken", valid_602361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602362 = header.getOrDefault("X-Amz-Target")
  valid_602362 = validateParameter(valid_602362, JString, required = true, default = newJString(
      "AmazonForecast.ListPredictors"))
  if valid_602362 != nil:
    section.add "X-Amz-Target", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Signature")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Signature", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Content-Sha256", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Date")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Date", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Credential")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Credential", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Security-Token")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Security-Token", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Algorithm")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Algorithm", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-SignedHeaders", valid_602369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602371: Call_ListPredictors_602357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of predictors created using the <a>CreatePredictor</a> operation. For each predictor, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribePredictor</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ## 
  let valid = call_602371.validator(path, query, header, formData, body)
  let scheme = call_602371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602371.url(scheme.get, call_602371.host, call_602371.base,
                         call_602371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602371, url, valid)

proc call*(call_602372: Call_ListPredictors_602357; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPredictors
  ## Returns a list of predictors created using the <a>CreatePredictor</a> operation. For each predictor, this operation returns a summary of its properties, including its Amazon Resource Name (ARN). You can retrieve the complete set of properties by using the ARN with the <a>DescribePredictor</a> operation. You can filter the list using an array of <a>Filter</a> objects.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602373 = newJObject()
  var body_602374 = newJObject()
  add(query_602373, "MaxResults", newJString(MaxResults))
  add(query_602373, "NextToken", newJString(NextToken))
  if body != nil:
    body_602374 = body
  result = call_602372.call(nil, query_602373, nil, nil, body_602374)

var listPredictors* = Call_ListPredictors_602357(name: "listPredictors",
    meth: HttpMethod.HttpPost, host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.ListPredictors",
    validator: validate_ListPredictors_602358, base: "/", url: url_ListPredictors_602359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDatasetGroup_602375 = ref object of OpenApiRestCall_601389
proc url_UpdateDatasetGroup_602377(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDatasetGroup_602376(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602378 = header.getOrDefault("X-Amz-Target")
  valid_602378 = validateParameter(valid_602378, JString, required = true, default = newJString(
      "AmazonForecast.UpdateDatasetGroup"))
  if valid_602378 != nil:
    section.add "X-Amz-Target", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Signature")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Signature", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Content-Sha256", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Date")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Date", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Credential")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Credential", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Security-Token")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Security-Token", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Algorithm")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Algorithm", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-SignedHeaders", valid_602385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602387: Call_UpdateDatasetGroup_602375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Replaces the datasets in a dataset group with the specified datasets.</p> <note> <p>The <code>Status</code> of the dataset group must be <code>ACTIVE</code> before you can use the dataset group to create a predictor. Use the <a>DescribeDatasetGroup</a> operation to get the status.</p> </note>
  ## 
  let valid = call_602387.validator(path, query, header, formData, body)
  let scheme = call_602387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602387.url(scheme.get, call_602387.host, call_602387.base,
                         call_602387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602387, url, valid)

proc call*(call_602388: Call_UpdateDatasetGroup_602375; body: JsonNode): Recallable =
  ## updateDatasetGroup
  ## <p>Replaces the datasets in a dataset group with the specified datasets.</p> <note> <p>The <code>Status</code> of the dataset group must be <code>ACTIVE</code> before you can use the dataset group to create a predictor. Use the <a>DescribeDatasetGroup</a> operation to get the status.</p> </note>
  ##   body: JObject (required)
  var body_602389 = newJObject()
  if body != nil:
    body_602389 = body
  result = call_602388.call(nil, nil, nil, nil, body_602389)

var updateDatasetGroup* = Call_UpdateDatasetGroup_602375(
    name: "updateDatasetGroup", meth: HttpMethod.HttpPost,
    host: "forecast.amazonaws.com",
    route: "/#X-Amz-Target=AmazonForecast.UpdateDatasetGroup",
    validator: validate_UpdateDatasetGroup_602376, base: "/",
    url: url_UpdateDatasetGroup_602377, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
